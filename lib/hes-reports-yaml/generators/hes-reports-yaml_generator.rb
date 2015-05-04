require 'rails/generators'
require 'rails/generators/migration'

# HES generator module
module Hes
  
  # Creates HesReportsYaml models, migrations, controllers, etc needed for gem to work
  class ReportsYamlGenerator < Rails::Generators::Base
    desc "Creates HesReportsYaml files based on config file"
    include Rails::Generators::Migration

    # Implement the required interface for Rails::Generators::Migration.
    # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

    # Installs files
    # @example
    #  template 'models/like.rb', "app/models/like.rb"
    def create_yaml_files
      template 'report_setup_template.yml', "default/report_setup.yml"
      template 'reports_template.yml', "default/report.yml"
      template 'report_setup_template.yml', "default/report_setup-backup.yml"
      template 'reports_template.yml', "default/report-backup.yml"
    end
    
    
    # The source root
    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end
  end
end
