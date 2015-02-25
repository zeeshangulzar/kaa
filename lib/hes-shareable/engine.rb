require File.dirname(__FILE__) + '/acts_as_shareable'
require File.dirname(__FILE__) + '/shareable_user_methods'

module HesShareable
  # Engine for initializing likes when the app starts
  class Engine < ::Rails::Engine
    ActiveRecord::Base.send(:include, HesShareable::ActsAsShareable)
    ActiveResource::Base.send(:include, HesShareable::ActsAsShareable)
    ActiveRecord::Base.send(:extend, HesShareable::ShareableUserMethods)
  end
end
