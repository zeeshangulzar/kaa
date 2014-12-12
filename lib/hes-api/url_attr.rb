# HES Api module
module HESApi
  # Adds a url attribute to all ActiveRecord models and includes it automatically in JSON representation of the model
  module UrlAttr

    # When the module is included, attr_accessor for url is added and serialziable_hash is chained
    # @param [ActiveRecord] base to extend
    def self.included(base)
      base.send(:attr_accessor, :url)

      base.send(:alias_method_chain, :serializable_hash, :url)

      class << base
        attr_accessor :custom_url
      end
    end

    # serialziable_hash is chained so that url is included in JSON
    def serializable_hash_with_url(options = nil)
      if options && options[:methods]
        options[:methods] << "url"
      else
        options = (options || {}).merge(:methods => ["url"])
      end

      serializable_hash_without_url(options)
    end
  end
end
