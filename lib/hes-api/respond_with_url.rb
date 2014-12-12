# HES Api module
module HESApi
  # Adds a URL to all json or xml representations of an active record model return in a action controller.
  # Does this to satisfy the standard that clients of an API should not have to generate the url themselves.
  module RespondWithUrl

    # When a controller has this module included a method chain is set up to extend respond_with
    # @param [ActionController::Base] base to extend
    def self.included(base)
      base.send(:alias_method_chain, :respond_with, :url)
    end

    # Chains the respond_with method in a controller so the URL attribute can be set on a model.
    # Calls the original respond_with method always after URL is added.
    def respond_with_with_url(*resources)
      
      # ActiveRecord collection
      if resources.first.is_a?(Array)
        resources.first.each{|x| add_url(x, :is_collection => true)}

        # Single ActiveRecord
      else
        
        # Need to append id to end of a deleted ActiveRecord since url_for does not create it correctly.
        # May be against API guidelines by returning URL (or even JSON) for a deleted record but no harm is really done by doing so.
        add_url(resources.first, :url => get_resource_url(resources.first))
      end

      respond_with_without_url(*resources)
    end

    # Adds the url to an ActiveRecord model and also works with IncludeInJSON to add url to associations that
    # are supposed to be rendered in json also.
    # @param [ActiveRecord] resource that will have url added
    # @param [Hash] options that override the default URL
    # @example
    #  add_url(@target_user)
    #  add_url(@target_user, :url => "/my_profile")
    def add_url(resource, options = {})
      return unless resource.class.respond_to?(:associations_in_json) && resource.class.respond_to?(:custom_url)

      resource.url = options[:url] || get_resource_url(resource)
      is_collection = options[:is_collection] || false

      # Loop through all associations that are supposed to be included in JSON
      resource.class.associations_in_json && (resource.class.associations_in_json.collect{|x| x.is_a?(Array) ? x.first.to_sym : x.to_sym} - (resource.ignore_associations_in_json || [])).each do |association|
        resources = resource.send(association)
        if resources.is_a?(Array)
          resources.each do |resources_resource|
            if resources_resource.respond_to?(:ignore_associations_in_json)
              resources_resource.ignore_associations_in_json ||= []
              resources_resource.ignore_associations_in_json << (!is_collection ? underscore(resource.class.to_s).to_sym : underscore(resource.class.to_s.pluralize).to_sym)
              add_url(resources_resource, :is_collection => true)
            end
          end
        elsif !resources.nil?
          if resources.respond_to?(:ignore_associations_in_json)
            resources.ignore_associations_in_json ||= []
            resources.ignore_associations_in_json << (!is_collection ? underscore(resource.class.to_s).to_sym : underscore(resource.class.to_s.pluralize).to_sym)
            add_url(resources)
          end
        end
      end
    end

    def get_resource_url(resource)
      return unless resource.class.respond_to?(:custom_url)
      resource.class.custom_url.nil? ? !resource.is_destroyed ? url_for(resource) : "#{url_for(resource)}/#{resource.id}" : resource.send(resource.class.custom_url, self)
    end

    # Underscore copied from Rails inflections
    def underscore(string)
      string.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end
  end
end
