# abstraction layer between models and active record
class ApplicationModel < ActiveRecord::Base

  self.abstract_class = true
  def all_attrs
    return *self.class.column_names
  end

  def url
    return '/' + self.class.table_name.to_s + '/' + self.id.to_s
  end

  def as_json(options = nil)
    parent_class = self.class.table_name
    hash = serializable_hash(options)

    if defined?(options[:meta]) && options[:meta] === false
      return hash
    end

    tables = self.connection.tables

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
    hash
  end
  
end