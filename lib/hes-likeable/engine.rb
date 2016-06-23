require 'hes-authorization'

require File.dirname(__FILE__) + '/acts_as_likeable'
require File.dirname(__FILE__) + '/likeable_user_methods'

module HesLikeable

  # Engine for initializing likes when the app starts
  class Engine < ::Rails::Engine
    
#    initializer "hes-likeable.likeable" do |app|
      ActiveRecord::Base.send(:include, HesLikeable::ActsAsLikeable)
      ActiveResource::Base.send(:include, HesLikeable::ActsAsLikeable)
      ActiveRecord::Base.send(:extend, HesLikeable::LikeableUserMethods)
 #   end

  end
end
