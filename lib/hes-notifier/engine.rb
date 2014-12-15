require "hes-authorization"
#require "hes-api"
require File.dirname(__FILE__) + "/acts_as_notifier"
require File.dirname(__FILE__) + "/has_notifications"
#require File.dirname(__FILE__) + "/generators/notifier_generator"

module HesNotifier
  # Engine for initializing notifications when the app starts
  class Engine < ::Rails::Engine
    #initializer "hes-notifier" do |app|
      ActiveRecord::Base.send :include, HesNotifier::ActsAsNotifier::Base
      ActiveRecord::Base.send :extend, HesNotifier::HasNotifications
    #end

    #config.generators do |g|
    #  g.test_framework :rspec, :view_specs => false
    #end
  end
end
