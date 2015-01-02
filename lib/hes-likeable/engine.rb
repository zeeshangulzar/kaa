require 'hes-authorization'
#require 'hes-api'
require 'hes-events'

require File.dirname(__FILE__) + '/acts_as_likeable'
require File.dirname(__FILE__) + '/likeable_user_methods'



module HesLikeable

  # Engine for initializing likes when the app starts
  class Engine < ::Rails::Engine
    
    # Lets us have after_like and after_unlike callbacks defined in models and only initialized if needed
    ActiveRecord::Base.send(:lazy_event_accessor, :after_like)
    ActiveRecord::Base.send(:lazy_event_accessor, :after_unlike)
    ActiveResource::Base.send(:lazy_event_accessor, :after_like)
    ActiveResource::Base.send(:lazy_event_accessor, :after_unlike)

#    initializer "hes-likeable.likeable" do |app|
      ActiveRecord::Base.send(:include, HesLikeable::ActsAsLikeable)
      ActiveResource::Base.send(:include, HesLikeable::ActsAsLikeable)
      ActiveRecord::Base.send(:extend, HesLikeable::LikeableUserMethods)
 #   end


  end
end
