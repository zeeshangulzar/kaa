# HES Api module
module HESApi
  # IncludeInJSON module that allows associations to easily be included in json rendered by a class
  module IncludeInJSON

    # When the module is included, it's extended with the class methods and set up for requiring let associations specify if they should be allowed in the json
    # @param [ActiveRecord] base to extend
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:include, ClassLevelInheritableAttributes)

      base.send(:alias_method_chain, :serializable_hash, :included_associations)

      base.send(:attr_accessor, :ignore_associations_in_json)
      base.send(:attr_accessor, :include_associations_in_json)

      class << base; attr_accessor :associations_in_json end
      class << base; attr_accessor :explicit_json_include end
      base.send("explicit_json_include=", false)
      base.send(:inheritable_attributes, :associations_in_json, :explicit_json_include)
    end

    # Class methods for overriding associations methods
    module ClassMethods
      # Overrides the belongs_to association call to test if an :in_json => true option has been included
      # @example
      #  class User < ActiveRecord::Base
      #    belongs_to :user, :in_json => true
      def belongs_to(*args)
        if args[1] && args[1][:in_json]
          self.associations_in_json ||= []
          self.associations_in_json << args.first
        end

        args[1] && args[1].delete(:in_json)

        super
      end

      # Overrides the belongs_to association call to test if an :in_json => true option has been included
      # @example
      #  class User < ActiveRecord::Base
      #    has_one :contact, :in_json => true
      def has_one(*args)
        if args[1] && args[1][:in_json]
          self.associations_in_json ||= []
          self.associations_in_json << args.first
        end
        
        args[1] && args[1].delete(:in_json)

        super
      end

      # Overrides the has_many association call to test if an :in_json => true option has been included
      # @example
      #  class User < ActiveRecord::Base
      #    has_many :contacts, :in_json => true
      def has_many(*args)
        if args[1] && args[1][:in_json]
          self.associations_in_json ||= []
          self.associations_in_json << (args[1][:as] ? [args.first, args[1][:as]] : args.first)
        end

        args[1] && args[1].delete(:in_json)

        super
      end
    end

    # Instance methods for chaining as_json
    module InstanceMethods

      # Overrides the as_json method so that assocations with :as_json => true are included be default
      def serializable_hash_with_included_associations(options = {})

        # Need to remove circular associations here so we don't go in an infinite loop
        associations_to_include_in_json = remove_circular_associations

        if (!self.class.explicit_json_include || self.include_associations_in_json)
          options ||= {}
          options = options.merge({:include => associations_to_include_in_json.collect{|x| x.is_a?(Array) ? x.first.to_s : x.to_s}}) if associations_to_include_in_json&& !options[:include]

          ignore_potential_circular_associations(associations_to_include_in_json)
        end

        # Remove ignored associations so that this instance can have as_json called on it again
        self.ignore_associations_in_json = nil

        serializable_hash_without_included_associations(options)
      end

      :private

      # Adds model that was just called as an association to ignore on association model or models instances to avoid circular calls
      # @param [Array<Symbols>] associations that are being included in serializable hash
      def ignore_potential_circular_associations(associations)

        # Loop through all associations that have :in_json => true option
        associations && associations.each do |association_sym|

          # Check if polymorphic association
          polymophic_association_sym = association_sym.last if association_sym.is_a?(Array)
          association_sym = association_sym.first if association_sym.is_a?(Array)

          # Get instance or instances 
          association = self.send(association_sym)

          # Add current class name to instance or instances to ignore in case they have an association back that contains the :in_json => true option
          if association.is_a?(Array)
            association.each{ |x| x && x.respond_to?(:ignore_associations_in_json) && x.ignore_associations_in_json ||= [] and x.ignore_associations_in_json << (polymophic_association_sym || self.class.name.underscore.to_sym) }
          elsif association
            if association.respond_to?(:ignore_associations_in_json)
              association.ignore_associations_in_json ||= []
              association.ignore_associations_in_json << (polymophic_association_sym || self.class.name.underscore.to_sym)
            end
          end

        end
      end

      # Removes associations that have already been serialized
      def remove_circular_associations

        # Copy array since we don't want to permanently remove associations
        associations_to_include_in_json = Array.new(self.class.associations_in_json || [])

        if associations_to_include_in_json && self.ignore_associations_in_json
          ignore_associations_in_json.each do |ignored_association|
            associations_to_include_in_json = associations_to_include_in_json.to_a.delete_if{|x| x.is_a?(Array) ? x.last == ignored_association : x == ignored_association}
          end
        end

        associations_to_include_in_json
      end
    end
  end
end
