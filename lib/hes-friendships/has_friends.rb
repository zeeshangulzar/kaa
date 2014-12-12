# Friendships Namespace
module HesFriendships
  # HasFriendships Module
  module HasFriends
    # When the module is included, it's extended with the class methods
    # @param [ActiveRecord] base to extend
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    # ClassMethods module for adding methods for friendships
    module ClassMethods

      # Defines an assocation where the model contains many friendships
      #
      # @example
      #  class User < ActiveRecord::Base
      #    has_friendships
      #    ...
      def has_friendships
        self.send :has_many, :friendships, :as => :friender, :dependent => :destroy
        self.send :has_many, :inverse_friendships, :as => :friendee, :class_name => "Friendship", :foreign_key => :friendee_id, :dependent => :destroy if HesFriendships.create_inverse_friendships
        self.send :include, FriendshipsInstanceMethods
      end
    end

    # Module that includes instance methods for models that have has_many association with friendships
    module FriendshipsInstanceMethods
      
      # When the module is included, it's extended with the class methods
      # @param [ActiveRecord] base to extend
      def self.included(base)
        base.send :after_create, :associate_requested_friendships if HesFriendships.allows_unregistered_friends
        base.send :after_update, :check_if_email_has_changed_and_associate_requested_friendships if HesFriendships.allows_unregistered_friends
        base.send :after_create, :auto_accept_friendships if HesFriendships.auto_accept_friendships
      end

      def friends
        @friends ||= self.class.where(:id => self.friendships.where(:friendee_type => self.class, :status => Friendship::STATUS[:accepted]).collect(&:friendee_id))
      end
      
      # Requests a friendship from another user or email address
      #
      # @param [User, String] user_or_email of user if exists, otherwise just use email address
      # @return [Friendship] instance of your friendship with other user, status will be 'requested'
      # @example
      #  @target_user.request_friend(another_user)
      #  @target_user.request_friend("developer@hesonline.com")
      # @todo Try to find user if string is passed in. Not sure if good idea because will have to know structure of database for this to work.
      def request_friend(user_or_email)
        unless user_or_email.is_a?(String)
          friendships.create(:friendee => user_or_email, :status => Friendship::STATUS[:requested])
        else
          friendships.create(:friend_email => user_or_email, :status => Friendship::STATUS[:requested])
        end
      end

      # Checks for friendship requests before user was registered by email address.
      # If any are found, updates friendships tied to other user while creating one for this user
      #
      # @param [String] email address if want to check for email not associated with user
      # @note Called in after_create by default
      def associate_requested_friendships(email = nil)
        Friendship.all(:conditions => ["(`#{Friendship.table_name}`.`friend_email` = :email) AND `#{Friendship.table_name}`.`status` = '#{Friendship::STATUS[:requested]}'", {:email => email || self.email}]).each do |f|
          friendships.create(:friendee => f.friender, :status => Friendship::STATUS[:pending])
          f.update_attributes(:friendee => self)
        end
      end

      # Auto accepts friendships after they are created if auto_accept_friendships is set to true in the config file.
      def auto_accept_friendships
        # TODO
      end

      # Checks to see if email address has changed after user is updated.
      # Calls check_for_requested_friendships if email was updated.
      # @see #check_for_requested_friendships
      def check_if_email_has_changed_and_associate_requested_friendships
        if email_was != email
          associate_requested_friendships
        end
      end
    end
  end
end
