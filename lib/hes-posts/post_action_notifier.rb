module HesPosts

  # Handles notifications when certain actions are taken on a post
  module PostActionNotifier

    # Included on post model
    def self.included(post_class)
      # Post instance can send notifications to a user
      post_class.send(:acts_as_notifier)
      post_class.send(:include, PostActionNotifierInstanceMethods)

      # Like actions
      post_class.send(:after_like, :create_post_owner_notification_of_like)
      post_class.send(:after_unlike, :destroy_post_owner_notification_of_like)

      # Reply actions
      post_class.send(:after_reply, :create_post_owner_notification_of_reply)
      post_class.send(:after_reply_destroyed, :destroy_post_owner_notification_of_reply)
    end

    # Callback methods for post actions
    module PostActionNotifierInstanceMethods

      # Creates a notification after a post is liked
      # @param [Like] like that was generated from liking this post
      # @return [Notification] notification that was generated after liking post
      # @note Notification title and message can be edited in hes-posts_config file in config/initializers folder.
      def create_post_owner_notification_of_like(like)
        unless self.user.role == "Poster"
          self.notify(self.user, HesPosts.post_liked_notification_title.call(self, like), HesPosts.post_liked_notification_message.call(self, like), :from_user => like.user, :key => post_like_notification_key(like))
        else
          self.postable.notify(self.user, HesPosts.post_liked_notification_title.call(self.postable, like), HesPosts.expert_post_liked_notification_message.call(self.postable, like), :from_user => like.user, :key => post_like_notification_key(like))
        end
      end

      # Creates a notification after a post is liked
      # @param [Like] like that was generated from liking this post
      # @return [Boolean] true if notification was destroyed, false if it was not
      def destroy_post_owner_notification_of_like(like)
        unless self.user.role == "Poster"
          self.notifications.find_by_key(post_like_notification_key(like)).destroy rescue true
        else
          self.postable.notifications.find_by_key(post_like_notification_key(like)).destroy rescue true
        end
      end

      # The key that is generated to find likes tied to a notification
      # @param [Like] like used for notification key
      # @return [String] key that will be used to create notification
      def post_like_notification_key(like)
        "post_like_#{like.id}"
      end


      # Creates a notification after a post is replied to
      # @param [Post] reply post
      # @return [Notification] notification that was generated after replying to post
      # @note Notification title and message can be edited in hes-posts_config file in config/initializers folder.
      def create_post_owner_notification_of_reply(reply)

        unless self.user.role == "Poster"
          self.notify(self.user, HesPosts.post_replied_notification_title.call(self, reply), HesPosts.post_replied_notification_message.call(self, reply), :from_user => reply.user, :key => post_reply_notification_key(reply))
        else
          self.postable.notify(self.postable.user, HesPosts.post_replied_notification_title.call(self.postable, reply), HesPosts.expert_post_replied_notification_message.call(self.postable, reply), :from_user => reply.user, :key => post_reply_notification_key(reply))
        end
      end

      # Destroys the notification after a post reply is destroyed
      # @return [Boolean] true if notification was destroyed, false if it was not
      def destroy_post_owner_notification_of_reply(reply)
        unless self.user.role == "Poster"
          self.notifications.find_by_key(post_reply_notification_key(reply)).destroy rescue true
        else
          self.postable.notifications.find_by_key(post_reply_notification_key(reply)).destroy rescue true
        end
      end

      # The key that is generated to find replies tied to a notification
      # @param [Post] reply used for notification key
      # @return [String] key that will be used to create notification
      def post_reply_notification_key(reply)
        "post_reply_#{reply.id}"
      end
    end
  end
end
