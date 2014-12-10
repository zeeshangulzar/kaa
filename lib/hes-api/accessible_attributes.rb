# HES Api module
module HESApi
  # Returns a list of accessible attributes on the instance of an ActiveRecord model
  module AccessibleAttributes
    # List attributes that are accessible. Useful for figuring out what can be posted to server.
    # @return [Hash] attributes that can be mass updated.
    def accessible_attributes
      attributes.delete_if {|key, value| !self.class.accessible_attributes.include?(key) }
    end
  end
end
