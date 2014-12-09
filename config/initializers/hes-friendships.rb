require "hes-friendships/engine"

# Friendships module
module HesFriendships
	mattr_accessor :allows_unregistered_friends, :auto_accept_friendships, :create_inverse_friendships, :label
	@@allows_unregistered_friends = true
	@@auto_accept_friendships = false
	@@create_inverse_friendships = true
	@@label = "Friend"
end
