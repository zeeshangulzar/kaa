module HESApi
  # Marks a module as destroyed if it was just successfully deleted
  module MarkAsDestroyed
    # Extends ActiveRecord::Base to mark models as they are destroyed
    def self.included(base)
      base.send(:include, MarkAsDestroyedInstanceMethods)
      base.send(:attr_accessor, :is_destroyed)
      base.send(:after_destroy, :mark_as_destroyed)
    end
    
    # Instance methods for mark as destroyed models
    module MarkAsDestroyedInstanceMethods
      # Sets the attribute to is destroyed
      def mark_as_destroyed
        self.is_destroyed = true
      end
    end
  end
end