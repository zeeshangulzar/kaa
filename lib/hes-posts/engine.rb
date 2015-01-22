require "hes-authorization"
#require "hes-api"
#require "hes-likeable"
#require "hes-notifier"
require 'hes-events'
require 'carrierwave'

require File.dirname(__FILE__) + "/post_validator"
require File.dirname(__FILE__) + "/has_wall"
require File.dirname(__FILE__) + "/is_postable"
require File.dirname(__FILE__) + "/post_action_notifier"
require File.dirname(__FILE__) + "/user_post_methods"


module HesPosts
  # Engine to start up HES posts
  class Engine < ::Rails::Engine
  	#initializer "hes-posts" do |app|
  		ActiveRecord::Base.send(:extend, HesPosts::HasWall)
  		ActiveRecord::Base.send(:extend, HesPosts::IsPostable)
   #   Post.send(:include, HesPosts::PostActionNotifier) if HesPosts.uses_notifications
      ActiveRecord::Base.send(:extend, HesPosts::UserPostMethods)
  #	end

  end
end
