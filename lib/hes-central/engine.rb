#require 'hes-api'
require "hes-authorization"

require File.dirname(__FILE__) + "/central_resource"
#require File.dirname(__FILE__) + "/generators/hes-central-config_generator"

module HesCentral

  # Engine to initialize HesCentral
  class Engine < ::Rails::Engine

    initializer "HesContactRequests" do |app|
      puts "HesCentral variables have not been set. Please run 'rails generate hes:central:config' and set all fields for the application." if HesCentral.application_repository_name.nil?
    end

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end

end
