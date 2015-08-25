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

  # call Model.attach(:attachment) to include the assc. or object in json for a particular request/method
  def attach(attachment_name, attachment = 'no attachment')
    @attachments = [] if !@attachments
    if attachment_name.is_a?(Symbol) && self.respond_to?(attachment_name)
      @attachments << attachment_name
    elsif attachment != 'no attachment'
      @attachments << [attachment_name.to_sym, attachment]
    end
  end

  # BEGIN CACHING MAGIC

  CLEAR_CACHES_DEFAULT = {
    :self         => true,
    :parents      => true,
    :ancestors    => false,
    :children     => false,
    :descendants  => false # THIS COULD BE DANGEROUS, NOT EVEN ENABLING ATM
  }

  @@CACHE_CONFIG = {}

  after_commit :clear_caches

  def cache_key
    return nil if !self.id
    return self.class.name.underscore.pluralize + "_" + self.id.to_s
  end

  def clear_cache
    Rails.logger.info "HESCACHE - clearing cache for: #{self.class.name}: #{self.id} (#{self.cache_key})"
    ApplicationController.hes_cache_clear(self.cache_key)
  end

  def clear_parent_caches(objects = [], ancestors = false)
    self.clear_cache
    Rails.logger.info "HESCACHE - clearing parent caches for #{self.class.name}: #{self.id}"
    objects = [objects] if !objects.is_a?(Array)
    objects.each{ |obj|
      obj.clear_parent_caches
    }
    refs = self.reflections.select do |association, reflection|
      reflection.macro == :belongs_to
    end
    refs.each{|ref|
      obj = self.send(ref.second.name)
      if obj && obj.class.attr_privacy
        obj.class.attr_privacy.each{ |rule|
          if rule[:attrs].include?(self.class.table_name.to_sym) || rule[:attrs].include?(self.class.name.downcase.to_sym) || (self.class.const_defined?('ASSOCIATED_CACHE_SYMBOLS') && !(rule[:attrs] & self.class::ASSOCIATED_CACHE_SYMBOLS).empty?)
            Rails.logger.info "HESCACHE - found belongs_to assoc. with privacy/json rule for: #{obj.class.name}"
            if ancestors
              obj.clear_parent_caches([], true)
            else
              obj.clear_cache
            end
          end
        }
      end
    }
  end

  def clear_child_caches(objects = [], descendants = false)
    self.clear_cache
    Rails.logger.info "HESCACHE - clearing child caches for #{self.class.name}: #{self.id}"
    objects = [objects] if !objects.is_a?(Array)
    objects.each{ |obj|
      obj.clear_child_caches
    }
    refs = self.reflections.select do |association, reflection|
      reflection.macro == :has_many || reflection.macro == :has_one
    end
    refs.each{|ref|
      objs = self.send(ref.second.name)
      next if !objs
      objs = [objs] if !objs.is_a?(Array)
      objs.each{ |obj|
        if obj.class.attr_privacy
          obj.class.attr_privacy.each{ |rule|
            if rule[:attrs].include?(self.class.table_name.to_sym) || rule[:attrs].include?(self.class.name.downcase.to_sym)
              Rails.logger.info "HESCACHE - found has_many or has_one assoc. with privacy/json for: #{obj.class.name}"
              if descendants
                # I HOPE YOU KNOW WHAT YOU'RE DOING!
                obj.clear_child_caches([], true)
              else
                obj.clear_cache
              end
            end
          }
        end
      }
    }
  end

  def clear_caches
    @@CACHE_CONFIG[self::class::name] = CLEAR_CACHES_DEFAULT.dup if !@@CACHE_CONFIG[self::class::name]
    cc = @@CACHE_CONFIG[self::class::name]
    self.clear_cache if cc[:self]
    self.clear_parent_caches if cc[:parents] && !cc[:ancestors]
    self.clear_parent_caches([], true) if cc[:ancestors]
    self.clear_child_caches if cc[:children] && !cc[:descendants]
    # NOT EVEN ENABLING THIS NEXT ONE UNTIL IF EVER IT MAKES SENSE OR WE CAN MAKE IT SAFE
    # self.clear_child_caches if cc[:descendants]
  end

  def self.clear_cache_for(*args)
    @@CACHE_CONFIG[self::name] = CLEAR_CACHES_DEFAULT.dup if !@@CACHE_CONFIG[self::name]
    cc = @@CACHE_CONFIG[self::name]
    cc.each{|k,v|
      cc[k.to_sym] = args.include?(k)
    }
  end

  # END CACHING MAGIC
  
end