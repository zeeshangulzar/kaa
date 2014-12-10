module HESApi
  # Inherits class level attributes
  module ClassLevelInheritableAttributes
    # Extends the base class when included
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    # Class methods for inheriting class attributes
    module ClassMethods
      
      # Class method for defining which attributes to inherit
      def inheritable_attributes(*args)
        @inheritable_attributes ||= [:inheritable_attributes]
        @inheritable_attributes += args
        args.each do |arg|
          class_eval %(
          class << self; attr_accessor :#{arg} end
          )
        end
        @inheritable_attributes
      end
      
      # Adds specified attributes when extended class in inherited
      def inherited(subclass)
        @inheritable_attributes.each do |inheritable_attribute|
          instance_var = "@#{inheritable_attribute}"
          subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
        end
      end
    end
  end
end
