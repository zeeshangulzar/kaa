require 'hes-authorization'
require 'hes-api'
require File.dirname(__FILE__) + '/has_friends'

# Friendships module
module HesFriendships
  # Engine for Friendships
  # @todo Test for hes-notifications and include FriendshipsNotifier if exists
  class Engine < ::Rails::Engine 
    ActiveRecord::Base.send :include, HesFriendships::HasFriends
  end
end