# HES Api module
module HESApi
  # Adds methods to make it easy to grab the parent when using nested resources
  module GetParent

    # Specifies which parents should be assigned variables in a before filter call
    # @param [String, Symbol] parent_name of model of nested resource
    # @param [Hash] get_parent_options that are mostly the same as a before_filter callback options, one additional is added to ignore throwing errors if parent is not found
    # @example
    #  get_parent :user
    #  get_parent :user, :except => :index
    #  get_parent :user, :only => [:index, :create]
    #  get_parent :user, :only => [:index, :create], :ignore_missing => :index
    # @note Defines two new methods get_[parent_name] and [parent]_found?
    def get_parent(parent_name, get_parent_options = {})

      self.send(:include, GetParentInstanceMethods) unless self.instance_methods.include?("get_parent")

      self.send(:define_method, "get_#{parent_name}") do
        get_parent(parent_name)
      end

      self.send(:define_method, "#{parent_name}_found?") do
        parent_found?(parent_name)
      end

      ignored_actions = [get_parent_options.delete(:ignore_missing)].flatten

      self.send(:before_filter, "get_#{parent_name}", get_parent_options)

      if get_parent_options.has_key?(:only)
        found_options = get_parent_options
        found_options[:only] = found_options[:only].to_ary
        ignored_actions.each do |ignored_action|
          found_options[:only].delete(ignored_action)
        end
      elsif get_parent_options.has_key?(:except)
        found_options = get_parent_options
        found_options[:except] = found_options[:except].to_ary
        found_options[:except].concat(ignored_actions).uniq!
      else
        found_options = get_parent_options
      end

      self.send(:before_filter, "#{parent_name}_found?", found_options)
    end

    # Instances methods for assigning a parent to a variable and checking if it was assigned
    module GetParentInstanceMethods
      # Assigns parent instance to a page variable using parent id passed in params
      # @param [String, Symbol] parent_name
      # @return [ActiveRecord::Base] instance of parent
      def get_parent(parent_name)
        eval("@#{parent_name} ||= #{parent_name.to_s.camelcase}.find_by_id(params[:#{parent_name}_id])")
      end

      # Checks to see if parent was found, renders unprocesable entity or 422 error if not
      # @param [String, Symbol] parent_name
      # @return [Boolean] true if found, false if not assigned
      def parent_found?(parent_name)
        eval("@#{parent_name}.nil? ? (render(:json => { :errors => [\"Must pass id of a #{parent_name}\"] }, :status => :unprocessable_entity) and false) : true")
      end
    end
  end
end
