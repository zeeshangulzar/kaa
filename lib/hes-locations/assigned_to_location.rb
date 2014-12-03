# HesLocations Namespace
module HesLocations
  # AssignedToLocation module
  module AssignedToLocation

    # When the module is included, it's extended with the class methods
    # @param controller [ActionController] controller to extend
    def self.included(controller)
      controller.send(:extend, ClassMethods)
    end

    # ClassMethods module for adding methods to own and/or be assigned to locations
    module ClassMethods

      # Defines a many to many association where a model belongs to one or many locations
      #
      # @example
      #  class User < ActiveRecord::Base
      #    assigned_to_location
      #    ...
      def assigned_to_location
        if ActiveRecord::Base.connection.table_exists? Location.table_name
          self.send(:many_to_many, :with => :location, :primary => self.to_s.underscore.to_sym)
          Location.send(:many_to_many, :with => self.to_s.underscore.to_sym, :primary => self.to_s.underscore.to_sym)
          self.send(:include, LocationAssignedInstanceMethods)
          self.send(:attr_accessible, :user_locations_attributes)
          # TODO: what's this for???
          # self.send(:accepts_nested_attributes_for, :user_locations)

        else
          puts "HesLocations table has not been created. Run 'rails generate hes:locations' to create migration for locations."
        end
        
        Location.assigned_models << self
      end
    end

    # Module that includes instance methods for models that have many_to_many association with locations
    module LocationAssignedInstanceMethods

      # Overrides the update_attributes method so that user locations are updated instead of created
      def update_attributes(attributes)
        need_location_reload = false

        # Destroy previous locations assigned to user
        if attributes[:user_locations_attributes]
          if attributes[:user_locations_attributes].collect{|x| x[:location_id]} != self.locations.collect(&:id)
            self.locations.destroy_all
            need_location_reload = true
          else
            attributes.delete(:user_locations_attributes)
          end
        end

        # run super method that will create new locations
        update_result = super

        # Reload locations since we updated them but will be cached on instance in previous form
        self.locations.reload if need_location_reload

        # Return result of update_attributes
        update_result
      end

      # Gets the top location that the assigned belongs to
      #
      # @return [Location] that has a depth of 1
      def top_location
        locations.first
      end

      # Gets the bottom location that the assigned belongs to
      #
      # @return [Location] that has a the deepest depth
      def location
        locations.last
      end

      def as_json(options = {})
        json_hash = super
        json_hash['location'] = self.location && self.location.name
        json_hash
      end
    end
  end
end