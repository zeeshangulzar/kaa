require "hes-authorization"
#require "hes-api"
#require "hes-likeable"
require "hes-events"

require File.dirname(__FILE__) + '/acts_as_commentable'
require File.dirname(__FILE__) + '/commentable_user_methods'

#require File.dirname(__FILE__) + '/generators/hes-commentable_generator'

ActiveRecord::Base.send(:lazy_event_accessor, :after_comment)
ActiveRecord::Base.send(:lazy_event_accessor, :after_uncomment)
ActiveResource::Base.send(:lazy_event_accessor, :after_comment)
ActiveResource::Base.send(:lazy_event_accessor, :after_uncomment)

module HesCommentable

  # Engine for initializing comments when the app starts
  class Engine < ::Rails::Engine

    #initializer "hes-commentable" do |app|
      ActiveRecord::Base.send :include, HesCommentable::ActsAsCommentable
      ActiveResource::Base.send :include, HesCommentable::ActsAsCommentable
      ActiveRecord::Base.send :extend, HesCommentable::CommentableUserMethods
   # end

  #  config.generators do |g|
 #     g.test_framework :rspec, :view_specs => false
   # end

  end

end
