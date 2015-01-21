require 'rails/generators'

module Hes

  # Generates files in the application that can easily be changed by programmer.
  # Use this instead of automatically generating them since a better history of the database is kept through migrations.
  class CloudStorageGenerator < Rails::Generators::Base

    desc "Creates configuration file with application key"
    argument :app_name, :type => :string

    # Installs engine
    def install
      cloud_url = "http://#{HesCloudStorage::USER}:#{HesCloudStorage::PASSWORD}@#{HesCloudStorage::SUBDOMAIN}.#{HesCloudStorage.configuration[:domain]}"
      begin
        @application = JSON.parse(RestClient.post("#{cloud_url}/applications", {:format => :json, :application => {:name => app_name}}))
      rescue
        applications = JSON.parse(RestClient.get("#{cloud_url}/applications", {:format => :json}))
        @application = applications.detect{|x| x["name"].downcase == app_name.downcase}

        raise "Could not create application and key" if @application.nil?
      end
      template("config_template.rb", "config/initializers/hes_cloud_config.rb")
    end

    # The source root
    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end
  end
end
