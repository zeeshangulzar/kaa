require "hes-authorization"

module HesContactRequests

  # Engine to initialize HesContactRequests
  class Engine < ::Rails::Engine

    initializer "HesContactRequests" do |app|
      puts "No ticketing system to send for contact requests has been set. If wanted, please run 'rails generate hes:contact_requests:config' and specify a ticket engine in config file." if HesContactRequests.ticket.nil?
    end

  end

end
