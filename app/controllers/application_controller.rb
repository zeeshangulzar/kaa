class ApplicationController < ActionController::Base
  protect_from_forgery

  respond_to :json

  before_filter :set_user_and_promotion
  before_filter :set_default_format_json

  HTTP_CODES = {
    'OK'        => 200,
    'DENIED'    => 403,
    'NOT_FOUND' => 404,
    'ERROR'     => 422
  }

  PAGE_SIZE = 20
  
  MeEquivalents = ['-', 'me']

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
        other_promotion = Promotion.find(params[:promotion_id])
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

  def HESResponder(body = 'AOK', status = 'OK')
    response_body = nil
    if status != 'OK'
      # we have an error of some sort..
      body = body.strip + " doesn't exist" if status == 'NOT_FOUND'
      body = [body] if !body.is_a?(Array)
      response = {:errors => body}
    elsif body.is_a?(String)
      # status is OK and body is a string..
      response = {:message => body}
    else
      response = body
    end

    code = HTTP_CODES.has_key?(status) ? HTTP_CODES[status] : (status.is_a? Integer) ? status : HTTP_CODES['ERROR']

    render :json => response, :status => code and return
  end

  def HESResponder2(body = 'AOK', status = 'OK', messages = nil)
    offset = !params[:offset].nil? && params[:offset].is_i? ? params[:offset].to_i : 0
    page_size = !params[:page_size].nil? && params[:page_size].is_i? ? params[:page_size].to_i : ApplicationController::PAGE_SIZE

    data = nil
    total_records = 0

    if status != 'OK'
      # we have an error of some sort..
      body = body.strip + " doesn't exist" if status == 'NOT_FOUND'
      body = [body] if !body.is_a?(Array)
      response = {:errors => body}
    elsif body.is_a?(String)
      # status is OK and body is a string..
      response = {:message => body}
    else
      # get the class.table_name for the root node name
      if body.is_a?(Array) || body.is_a?(Hash)
        # ActiveRecord collection
        if !body.first.nil? && !body.first.class.nil? && !body.first.class.table_name.nil?
          root = body.first.class.table_name.to_s
        end
      else
        # Single ActiveRecord
        if !body.class.nil? && !body.class.table_name.nil?
          root = body.class.table_name.to_s
        end
      end

      data = body.respond_to?('size') ? body.slice(offset, page_size) : [body]

      total_records = body.respond_to?('size') ? body.size : 1
      total_pages = (total_records.to_f / page_size.to_f).ceil
      current_page = (offset.to_f / page_size.to_f).ceil + 1

      response = {
        root => {
          :data => data,
          :meta => {
            :messages       => messages,
            :page_size      => page_size,
            :page           => current_page,
            :total_pages    => total_pages,
            :total_records  => total_records,
            :links   => {
              :current  => request.fullpath
            }
          }
        }
      }

      if total_records > page_size
        if offset > 0
          prev_offset = (offset - page_size) <= 0 ? nil : offset - page_size
          response[root][:meta][:links][:prev] = url_replace(request.fullpath, :merge_query => {'offset' => prev_offset})
        end
        if (offset + page_size) < total_records
          next_offset = offset + page_size
          response[root][:meta][:links][:next] = url_replace(request.fullpath, :merge_query => {'offset' => next_offset})
        end
      end

    end

    code = HTTP_CODES.has_key?(status) ? HTTP_CODES[status] : (status.is_a? Integer) ? status : HTTP_CODES['ERROR']

    render :json => response, :status => code and return

    #render :json => MultiJson.dump(response) and return
  end

  # Takes incoming param (expected to be a hash) and removes anything that cannot be
  # written in accordance with the incoming model Object. Then returns the scrubbed hash
  def scrub(param, model)
    allowed_attrs = model.accessible_attributes.to_a
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

end
