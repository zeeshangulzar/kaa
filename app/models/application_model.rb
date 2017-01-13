# abstraction layer between models and active record
class ApplicationModel < ActiveRecord::Base

  # TODO: implement better pagination through a scope such as below, in as_json object & associations, combined with HESResponder injecting paging params
  # scope :paginated, lambda{|limit,offset|
  #   limit(limit).offset(offset)
  # }

  self.abstract_class = true

  def all_attrs
    return *self.class.column_names
  end

  def url
    return '/' + self.class.table_name.to_s + '/' + self.id.to_s
  end

  def as_json(options = nil)
    ApplicationModel.benchmark 'ApplicationModel::as_json' do
      parent_class = self.class.table_name
      hash = serializable_hash(options)

      if @attachments
        # nice way to inject associations or whatever else into json from controller methods
        @attachments.each{ |attachment|
          if attachment.is_a?(Symbol) && self.respond_to?(attachment)
            hash[attachment] = self.send(attachment)
          elsif attachment.is_a?(Array)
            hash[attachment[0].to_sym] = attachment[1]
          end
        }
      end

      if defined?(options[:meta]) && options[:meta] === false
        return hash
      end

      tables = self.get_tables

      hash.keys.each do |key|
        if !options.nil? && !options[:do_not_paginate].nil? && options[:do_not_paginate].is_a?(Array)
          if options[:do_not_paginate].include?(key)
            next
          end
        end
        if tables.include?(key) && hash[key].is_a?(Array) && key != 'posts'
          data = hash[key].clone
          total_pages = (data.size.to_f / ApplicationController::PAGE_SIZE.to_f).ceil
          hash[key] = {
            :data => data.first(ApplicationController::PAGE_SIZE),
            :meta => {
              :messages       => nil,
              :page_size      => ApplicationController::PAGE_SIZE,
              :page           => 1,
              :total_pages    => total_pages,
              :total_records  => data.size,
              :links  => {
                :current   => '/' + parent_class + '/' + hash['id'].to_s + '/' + key.to_s
              }
            }
          }
          if data.size > ApplicationController::PAGE_SIZE
            hash[key][:meta][:links][:next] = '/' + parent_class + '/' + hash['id'].to_s + '/' + key.to_s + '?offset=' + ApplicationController::PAGE_SIZE.to_s
          end
        end
      end
      return hash
    end
  end

  # call Model.attach(:attachment) to include the assc. or object in json for a particular request/method
  def attach(attachment_name, attachment = 'no attachment')
    @attachments = [] if !@attachments
    if attachment_name.is_a?(Symbol) && self.respond_to?(attachment_name)
      @attachments << attachment_name
    elsif attachment != 'no attachment'
      @attachments << [attachment_name.to_sym, attachment]
    elsif attachment_name.is_a?(Hash)
      attachment_name.each{|name, attachment|
        @attachments << [name.to_sym, attachment]
      }
    end
  end

  def self.sanitize(input, options = {})
    output = super(input)
    if options[:no_wrap]
      output = output[1..-2]
    end
    return output
  end

  def get_tables
    @@tables ||= self.connection.tables
  end

  # BEGIN NEW NEW CACHING MAGIC!
  def cache_key(*things)
    begin
      case
      when timestamp = self[:updated_at]
        timestamp = timestamp.utc.to_s(:number)
        key = "#{self.class.model_name.cache_key}/#{id}-#{timestamp}"
      else
        key = "#{self.class.model_name.cache_key}/#{id}"
      end
      if self.class.const_defined?(:CACHE_KEY_INCLUDES)
        things = things + self.class.const_get(:CACHE_KEY_INCLUDES)
      end
      if !things.empty?
        @@object = self
        return "#{key}/#{ApplicationModel.construct_timestamp_hash(*things)}"
      end
      return key
    ensure
      @@object = false
    end
  end

  # accepts n arguments and attempts to detect each type and association to the parent @@object
  # then produces a max(:updated_at/:created_at) for each collection and MD5's the whole thing so the key doesn't get too long
  # the whole point here is to make a cache key that represents the latest updates for all collections,
  # thus ensuring the cache will implicitly break whenever something updates.. MAGIC!
  def self.construct_timestamp_hash(*things)
    timestamps = []
    things = [things] if !things.is_a?(Array)
    things.each do |thing|
      if thing.is_a?(Time)
        timestamps << thing
      elsif thing.is_a?(Date)
        timestamps << thing.to_time rescue nil
      elsif thing.is_a?(Symbol)
        # a symbol should represent an AR association i.e. :users
        # passing a symbol will provide far better performance than the actual object association
        # Example:
        # p = Promotion.first
        # p.cache_key(p.users) <- does select * from users, then max(updated_at)
        # p.cache_key(:users) <- only does select max(updated_at) from users
        if !!@@object && @@object.respond_to?(thing)
          if @@object.reflections[thing].klass.column_names.include?('updated_at')
            timestamps << @@object.send(thing).maximum(:updated_at).to_time rescue nil
          elsif @@object.reflections[thing].klass.column_names.include?('created_at')
            timestamps << @@object.send(thing).maximum(:updated_at).to_time rescue nil
          end
        end
      elsif thing.is_a?(Array) || thing.class.ancestors.include?(ApplicationModel) || thing.ancestors.include?(ApplicationModel)
        # passing the actual object association
        # as explained above, this is slower.. but may be necessary at some point?
        # this was written first and it should probably stick around until we're sure we can drop it
        if thing.respond_to?(:updated_at) || (thing.respond_to?("column_names") && thing.column_names.include?('updated_at'))
          timestamps << thing.maximum(:updated_at).to_time rescue nil
        elsif thing.respond_to?(:created_at) || (thing.respond_to?("column_names") && thing.column_names.include?('created_at'))
          timestamps << thing.maximum(:created_at).to_time rescue nil
        end
      end
    end
    timestamps.compact!
    return 'no-data' if timestamps.empty?
    return Digest::MD5::hexdigest(timestamps.join('/'))
  end
  # END NEW NEW CACHING MAGIC

  def self.where_flags(flags)
    # returns the ActiveRecord#where clause to query the flag_defs table
    sql = []
    flags.each do |key, value|
      i,p,v = index_position_value(self.flag_def.detect{|fd|fd.flag_name==key.to_s}.position)
      sql << "IF(#{self.table_name}.flags_#{i} & POW(2,#{p})=0,false,true) = #{value}"
    end
    where(sql.join(' AND '))
  end

end