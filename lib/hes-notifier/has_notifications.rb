# Notificationable module
module HesNotifier
  # Methods for have an ActiveRecord model to own notificaitons
  module HasNotifications
    def has_notifications
      self.send(:has_many, :notifications, :dependent => :destroy, :order => "created_at DESC")
    end
  end
end
