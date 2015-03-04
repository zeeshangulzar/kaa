require "hes-authorization"

require File.dirname(__FILE__) + "/generators/hes-contact-requests-config_generator"

module HesContactRequests

  # Engine to initialize HesContactRequests
  class Engine < ::Rails::Engine

    initializer "HesContactRequests" do |app|
      puts "No ticketing system to send for contact requests has been set. If wanted, please run 'rails generate hes:contact_requests:config' and specify a ticket engine in config file." if HesContactRequests.ticket.nil?
    end

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end

end
