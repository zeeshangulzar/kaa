class ApplicationController < ActionController::Base
  protect_from_forgery

  respond_to :json

  before_filter :set_user_and_promotion
  before_filter :set_default_format_json

  HTTP_CODES = {
    'OK'        => 200,
    'BAD'       => 400,
    'DENIED'    => 403,
    'NOT_FOUND' => 404,
    'ERROR'     => 422
  }

  PAGE_SIZE = 20
  
  MeEquivalents = ['-', 'me']

  rescue_from ActiveRecord::RecordNotUnique do |exception|
    return HESResponder("Record not unique", "ERROR")
  end

  # custom error class and rescue to catch errors from HESResponder and immediately render them
  # (in case HESResponder is called multiple times or is called via HESCachedResponder, or whatever else.. we don't want to continue)
  #   the other solution i thought of was to create a method like HESErrorResponder that raises
  #   HESError which in turn calls HESResponder to render the error immediately
  #   but this implementation does the same thing, for all intents and purposes
  #   without having to change HESResponder() everywhere we encounter an error
  #   NOTE: i've set this up to handle almost exactly what was just described, raising and rendering in the opposite order
  #         so you COULD raise HESError like so: raise HESError, [errors, status]
  #         and it will pass through to HESResponder without entering an infinite loop via the new argument "raised"
  class HESError < StandardError; end
  rescue_from HESError do |exception|
    if exception.message.is_a?(String)
      if response.code == '200'
        message = exception.message.to_s == "ApplicationController::HESError" ? "General Error" : exception.message
        # raise HESError was called directly in a controller with no args or with a string, shouldn't happen but whatevs
        render :json => {:errors => [message]}, :status => '422' and return
      else
        render :text => exception.message and return
      end
    elsif exception.message.is_a?(Array)
      return HESResponder(exception.message[0] || 'General Error', exception.message[1] || 'ERROR', nil, true)
    else
      return HESResponder(exception.message[:payload] || 'General Error', exception.message[:status] || 'ERROR', nil, true)
    end
  end

  def get_user_from_params_user_id
    user = @current_user
    id_to_check = (controller_name == "users") ? params[:id] : params[:user_id]
    if !id_to_check.nil? && !MeEquivalents.include?(id_to_check)
      user = User.find(id_to_check) rescue nil
      if !user
        return HESResponder("User", "NOT_FOUND")
      end
    end
    return user
  end

  # Sets the default format to json unless a different format is request.
  def set_default_format_json
    if params[:format] && params[:format] != 'json'
      head :bad_request
    else
      request.format = 'json' unless params[:format]
    end
  end

  def set_user_and_promotion
    # first set it to me and my promotion
    @current_user = HESSecurityMiddleware.current_user
    @target_user = self.get_user_from_params_user_id
    if @current_user
      # TODO: should this be driving off @current_user, @target_user, or both?
      @promotion = @current_user.promotion
      if params[:promotion_id]
        can_change_promotion = false
        other_promotion = Promotion.find(params[:promotion_id]) rescue nil
        if !other_promotion
          return HESResponder("Promotion", "NOT_FOUND")
        end
        if @current_user.master? || @current_user.poster?
          can_change_promotion = true
        elsif @current_user.reseller? && other_promotion.organization.reseller_id == @current_user.promotion.organization.reseller_id
          can_change_promotion = true
        elsif @current_user.coordinator? && other_promotion.organization_id == @current_user.promotion.organization_id
          can_change_promotion = true
        end
        if can_change_promotion
          @promotion = other_promotion 
        end
      end
      # last accessed & welcome back messages
      @current_user.process_last_accessed
    else
      # what if promotion does not exist or is not active????
      info = DomainConfig.parse(request.host)
      if info[:subdomain]
        promotion = Promotion.find_by_subdomain(info[:subdomain])
        if promotion && promotion.is_active
          @promotion = promotion
        end
      end
    end
  end

  # page_size of 0 = all records
  def HESResponder(payload = 'AOK', status = 'OK', page_size = nil, raised = false)

    if payload.is_a?(Hash) && payload.has_key?(:data) && payload.has_key?(:meta)
      # allow a complete response to pass right thru
      render :json => MultiJson.dump(payload), :status => HTTP_CODES['OK'] and return
    end
    
    unless !page_size.nil?
      # only allow overriding of page_size if it isn't passed
      page_size = (!params[:page_size].nil? && params[:page_size].is_i?) ? params[:page_size].to_i : ApplicationController::PAGE_SIZE
    end

    offset = !params[:offset].nil? && params[:offset].is_i? ? params[:offset].to_i : 0
    data = nil
    total_records = 0

    if status != 'OK'
      # we have an error of some sort..
      payload = payload.strip + " doesn't exist" if status == 'NOT_FOUND'
      payload = [payload] if !payload.is_a?(Array)
      response = {:errors => payload}
    elsif payload.is_a?(String)
      # status is OK and payload is a string..
      response = {:message => payload}
    else
      if payload.respond_to?('size')
        # generally, size() would indicate an array, however, I've come across instances where it's a hash
        payload = payload.to_a if payload.is_a?(Hash)
        # regardless, chop it up for paging..
        data = page_size > 0 ? payload.slice(offset, page_size) : payload
      else
        # singular object
        data = [payload]
      end

      total_records = payload.respond_to?('size') ? payload.size : 1
      total_pages = page_size > 0 ? (total_records.to_f / page_size.to_f).ceil : 1
      current_page = page_size > 0 ? (offset.to_f / page_size.to_f).ceil + 1 : 1

      response = {
        :data => data,
        :meta => {
          :page_size      => page_size,
          :page           => current_page,
          :total_pages    => total_pages,
          :total_records  => total_records,
          :links   => {
            :current  => request.fullpath
          }
        }
      }

      if page_size > 0
        # prev/next links will never exist if we're getting all records..
        if total_records > page_size
          if offset > 0
            prev_offset = (offset - page_size) <= 0 ? nil : offset - page_size
            response[:meta][:links][:prev] = url_replace(request.fullpath, :merge_query => {'offset' => prev_offset})
          end
          if (offset + page_size) < total_records
            next_offset = offset + page_size
            response[:meta][:links][:next] = url_replace(request.fullpath, :merge_query => {'offset' => next_offset})
          end
        end
      end
    end
    code = HTTP_CODES.has_key?(status) ? HTTP_CODES[status] : (status.is_a? Integer) ? status : HTTP_CODES['ERROR']
    payload_hash = MultiJson.dump(response)
    if status != 'OK' && !raised
      # catch everything except 200s and immediately render the error UNLESS already in a rescue attempt (raised = true)
      # see rescue_from HESError
      raise HESError, render_to_string(:json => payload_hash, :status => code)
    else
      render(:json => payload_hash, :status => code) and return payload_hash
    end
  end

  # BEGIN CACHING RELATED METHODS
  def HESCachedResponder(cache_key, payload = 'AOK', options = {})
    options = {
      :page_size => nil,
      :include_params_slug => false,
      :cache_options => {}
    }.nil_merge!(options)

    cache_miss = false

    if block_given?
      response = hes_cache_fetch(cache_key, options){
        cache_miss = true;
        HESResponder(yield, 'OK', options[:page_size])
      }
    else
      response = hes_cache_fetch(cache_key, options){
        cache_miss = true;
        HESResponder(payload, 'OK', options[:page_size])
      }
    end
    render :json => response, :status => HTTP_CODES['OK'] unless cache_miss
  end

  def hes_cache_fetch(cache_key, options= {})
    params_appendage = options[:include_params_slug] ? "_" + params_slug : ""
    timestamp_key = "HESCacheTimestamp_#{cache_key}"
    cached_timestamp = Rails.cache.read(timestamp_key)
    complete_cache_key = "HESCache_#{cache_key}#{params_appendage}"

    if cached_timestamp
      item = Rails.cache.read(complete_cache_key)
      if item && item.is_a?(Hash) && item[:timestamp] == cached_timestamp
        Rails.logger.warn "cache hit for #{complete_cache_key}"
        return item[:data]
      end
    end

    Rails.logger.warn "cache miss for #{complete_cache_key}"
    timestamp =  Time.now.utc
    Rails.cache.write(timestamp_key, timestamp, options[:cache_options])
    data = yield
    Rails.cache.write(complete_cache_key, {:timestamp=>timestamp, :data=>data}, options[:cache_options])
    return data
  end

  def self.hes_cache_clear(cache_key)
    timestamp_key = "HESCacheTimestamp_#{cache_key}"
    Rails.cache.delete(timestamp_key)
  end

  def params_slug
    params.
        keys.sort{|x,y| x.to_s<=>y.to_s}.
          collect{|k,v|"#{k}_#{params[k]}"}.
            join('_')
  end
  # END CACHING RELATED METHODS

  # Takes incoming param (expected to be a hash) and removes anything that cannot be
  # written in accordance with the incoming model or array. Then returns the scrubbed hash
  def scrub(param, model_or_array = [])
    allowed_attrs = model_or_array.is_a?(Array) ? model_or_array : model_or_array.accessible_attributes.to_a
    posted_attrs = param.stringify_keys.keys
    attrs_to_update = allowed_attrs & posted_attrs
    param.delete_if{|k,v|!attrs_to_update.include?(k)}
  end

  def get_user
    return @current_user
  end

  def url_replace(url, options = {})
    uri = URI.parse(URI.encode(url))
    hquery = !uri.query.nil? ? CGI::parse(uri.query) : {}
    components = Hash[uri.component.map { |key| [key, uri.send(key)] }]
    new_hquery = hquery.merge(options[:merge_query] || {}).select { |k, v| v }.map{|v|v.join('=')}
    new_query = new_hquery.join("&")
    new_components = {
      :path  => options[:path] || uri.path,
      :query => new_query
    }
    new_uri = URI::Generic.build(components.merge(new_components))
    URI.decode(new_uri.to_s)
  end

  def get_host
    if request.port != 80
      host = request.host_with_port
    else
      host = request.host
    end
    return host
  end

end
