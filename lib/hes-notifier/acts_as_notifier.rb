# Notificationable module
module HesNotifier
  # Methods for have an ActiveRecord model act as a notifier
  module ActsAsNotifier
    # Base module
    module Base
      # When the module is included, it's extended with the class methods
      # @param [ActiveRecord] base to extend
      def self.included(base)     
        base.send :extend, ClassMethods
      end

      # Class methods for adding methods for notifications
      module ClassMethods
        # Defines an assocation where the model contains many notifications
        #
        # @example
        #  class Recipe < ActiveRecord::Base
        #    acts_as_notifier
        #    ...
        def acts_as_notifier
          return unless ActiveRecord::Base.connection.tables.include?(self.to_s.tableize)
          return unless ActiveRecord::Base.connection.tables.include?('notifications')
            
          self.send(:has_many, :notifications, :as => :notificationable, :dependent => :destroy)
          self.send(:attr_accessor, :skip_notify)
          send :include, InstanceMethods
        end
      end

      # Module that includes instance methods for models that have notifications
      module InstanceMethods
        # Creates a new notification
        # 
        # @param [User] user that the notification is assigned to
        # @param [title] title of the notification
        # @param [message] message that the notification contains
        # @param [options] options including user that the notification came from and key
        def notify(user, title, message, options={})
          notifications.create(:title => title, :message => message, :user => user, :from_user => options[:from], :key => options[:key]) unless skip_notify
        end
      end
    end
  end
end
