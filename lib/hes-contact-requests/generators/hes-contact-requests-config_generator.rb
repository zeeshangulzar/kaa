require 'rails/generators'

# HES generator module
module Hes
  
  # ContactRequests generator module
  module ContactRequests
    
    # Generates a configuration file for HesContactRequests in the application's initializers folder that can easily be modified.
    class ConfigGenerator < Rails::Generators::Base
      desc "Creates configuration file for HesContactRequests"

      # Creates configuration file at /config/initializers/hes-contact-requests
      def install_config
        template("config_template.rb", "config/initializers/hes-contact-requests_config.rb")
      end
      
      # The source root
      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end
    end
  end
end