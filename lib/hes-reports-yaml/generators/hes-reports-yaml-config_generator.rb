require 'rails/generators'

# HES generator module
module Hes
  
  # ReportsYaml generator module
  module ReportsYaml
    
    # Generates a configuration file for HesReportsYaml in the application's initializers folder that can easily be modified.
    class ConfigGenerator < Rails::Generators::Base
      desc "Creates configuration file for HesReportsYaml"

      # Creates configuration file at config/initializers/hes-reports-yaml
      def install_config
        template("config_template.rb", "config/initializers/hes-reports-yaml_config.rb")
      end
      
      # The source root
      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end
    end
  end
end