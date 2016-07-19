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

  # BEGIN NEW CACHING MAGIC
  def self.max_timestamp(*things)
    timestamps = []
    things.each do |thing|
      if thing.is_a?(Time)
        timestamps << thing
      elsif thing.is_a?(Date)
        timestamps << thing.to_time
      elsif thing.is_a?(Array)
        timestamps << thing.maximum(:updated_at).to_time
      elsif thing.is_a?(ApplicationModel)
        if thing.respond_to?(:updated_at)
          ttimestamp << thing.maximum(:updated_at).to_time
        elsif thing.respond_to?(:created_at)
          timestamps << thing.maximum(:created_at).to_time
        end
      end
    end
    return timestamps.max.to_time.to_s(:number)
  end

  def cache_key(*things)
    case
    when timestamp = self[:updated_at]
      timestamp = timestamp.utc.to_s(:number)
      key = "#{self.class.model_name.cache_key}/#{id}-#{timestamp}"
    else
      key = "#{self.class.model_name.cache_key}/#{id}"
    end
    if !things.empty?
      return "#{key}/#{ApplicationModel.max_timestamp(*things)}"
    end
    return key
  end
  # END NEW CACHING MAGIC

end