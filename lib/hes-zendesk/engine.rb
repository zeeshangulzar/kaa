require File.dirname(__FILE__) + "/zendesk-ticket"

module HesZendesk

  # Engine to initialize HesZendesk
  class Engine < ::Rails::Engine

    initializer "HesZendesk" do |app|
      # Add code here to initialize HesZendesk
    end

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end

end
