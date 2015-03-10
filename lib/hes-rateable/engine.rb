require File.dirname(__FILE__) + '/acts_as_rateable'
require File.dirname(__FILE__) + '/rateable_user_methods'

module HesRateable
  # Engine for initializing likes when the app starts
  class Engine < ::Rails::Engine
    ActiveRecord::Base.send(:include, HesRateable::ActsAsRateable)
    ActiveResource::Base.send(:include, HesRateable::ActsAsRateable)
    ActiveRecord::Base.send(:extend, HesRateable::RateableUserMethods)
  end
end
