# HES Api module
module HESApi
  # Creates an alias method on a polymorphic model so it is easier to access "able" models
  module PolymorphicAlias

    # When the module is included, it's extended with the class methods and set up to define new methods when :as parameter is present in an association
    # @param [ActiveRecord] base to extend
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    # Class methods for overriding associations methods
    module ClassMethods
      # Overrides the belongs_to association call to test if an :as option has been included
      # @example
      #  class User < ActiveRecord::Base
      #    has_one :contact, :as => :contactable
      def has_one(*args)
        create_polymorphic_alias_method(args[1][:class_name] || args[0], args[1][:as]) if args[1] && args[1][:as]

        super
      end

      # Overrides the has_many association call to test if an :as option has been included
      # @example
      #  class User < ActiveRecord::Base
      #    has_many :contacts, :as => :contactable
      def has_many(*args)
        create_polymorphic_alias_method(args[1][:class_name] || args[0], args[1][:as]) if args[1] && args[1][:as]

        super
      end

      :private

      # Creates a new alias method that will use class name to access association as if it weren't polymorphic
      # @param [String, Symbol] polymorphic_association_name of the polymorphic model that needs to have new method defined
      def create_polymorphic_alias_method(polymorphic_association_name, polymorphic_name)
        polymorphic_class_name = self.to_s
        polymorphic_alias_method = self.to_s.underscore
        polymorphic_association_name.to_s.singularize.camelcase.constantize.send(:define_method, polymorphic_alias_method) do
          if polymorphic_class_name == self.send("#{polymorphic_name}_type")
            self.send(polymorphic_name)
          else
          # TODO: figure out why polys fail with this line...
          #  raise NoMethodError
          end

        end
      end
    end
  end
end
