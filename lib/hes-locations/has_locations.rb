# HesLocations Namespace
module HesLocations
  # HasHesLocations Module
  module HasHesLocations
    # When the module is included, it's extended with the class methods
    # @param controller [ActionController] controller to extend
    def self.included(controller)
      controller.send(:extend, ClassMethods)
    end

    # ClassMethods module for adding methods to own and/or be assigned to locations
    module ClassMethods

      # Defines an assocation where the model contains many locations
      #
      # @example
      #  class Promotion < ActiveRecord::Base
      #    has_locations
      #    ...
      def has_locations
        if column_names.include?("locations_depth")
          self.send(:has_many, :locations, :as => :locationable, :order => 'parent_location_id, sequence', :dependent => :destroy)
          self.send(:include, LocationOwnerInstanceMethods)
        else
          puts "#{self.to_s} does not have correct location columns defined. Run 'rails generator hes:locations' to add 'locations_depth' and 'location_labels' columns." unless defined?(RAKE_TASK)
        end

        Location.owner_models << self
      end
    end

    # Module that includes instance methods for models that have has_many association with locations
    module LocationOwnerInstanceMethods

      # Overrides the locations relation so that extra dynamic methods can be written to the relation
      #
      # @example
      #  @promotion.locations
      #  @promotion.locations.bottom
      #
      # @return [Array<ActiveRecord>] that is a active record relation with scoped bottom method based on the depth level of the locationable instance
      def locations
        _locations_depth = self.locations_depth
        locations_relation = super
        locations_relation_virtual_class = class << locations_relation; self end
        locations_relation_virtual_class.send :define_method, :bottom do
          level(_locations_depth)
        end
        locations_relation
      end

      # Overrides location_labels getter so that an array of labels is returned instead of pipe-delimited string
      #
      # @return [Array<String>] of location labels
      def location_labels
        self.read_attribute(:location_labels).split('|')
      end

      # Sets a location label at the nested level specified
      #
      # @example
      #  @promotion.set_location_label('State')
      #  @promotion.set_location_label('City', 2)
      #
      # @param [String] name of new location label
      # @param [Integer] level of label
      #
      # @note Does not actually save the instance, call save on model to commit
      def set_location_label(name, level = 1)
        _location_labels = location_labels
        _location_labels[level - 1] = name
        self.location_labels = _location_labels.join('|')
      end

      # Determines whether or not this locationable instance has nested locations
      #
      # @return [Boolean] true if has nested locations, false if only single level of locations
      def nested_locations?
        self.locations_depth > 1
      end

      # Gets the number of nested levels for a location dynamically instead of locations_depth attribute
      #
      # @return [Integer]
      def location_levels
        locations.except(:order).order('depth DESC').first.depth || 1 rescue 1
      end
    end
  end
end
