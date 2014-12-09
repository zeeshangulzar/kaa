# Friendships module
module HesFriendships
  # Notifies friends that they have a friendship using hes-notifier
  module FriendshipNotifier
    
    # When the module is included, it's extended with the class methods
    # @param [ActiveRecord] base to extend, most likely Friendship
    def self.included(base)
        base.send :acts_as_notifier
      base.send :after_create, :send_notification
      base.send :after_update, :send_assigned_friend_notification
      base.send :after_update, :mark_friendship_notification_as_viewed
    end

    
    # Sends notification to the user that friendship was requested of
    # @note Sent after friendships is created
    def send_notification
      notify(friend, "#{Label} Request", "#{user.first_name} #{user.last_name} has requested to be your <a href='/#{Friendship::Label.pluralize.urlize}'>#{Friendship::Label}</a>.",
             :from => user, :key => "friendship_#{id}") unless friend.nil? || status == Friendship::STATUS[:accepted]
    end
    
    # Sends notification if friendships is updated with a friend id
    # @note Called after friendships is updated
    # @see #send_notification
    def send_assigned_friend_notification
      send_notification if friend_id_was.nil? && friend_id
    end
    
    # Removes notification after friendships has been accepted or declined
    # @note Called after friendshps is updated
    def mark_notification_as_viewed
      notifications.each{|n| n.update_attributes(:viewed => true)} if (status == Friendship::STATUS[:accepted] || status == Friendship::STATUS[:declined]) && status_was == Friendship::STATUS[:pending]
    end
  end
end
