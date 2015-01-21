require "carrierwave"
require "rest_client"

require File.dirname(__FILE__) + "/hes_cloud_url"
require File.dirname(__FILE__) + "/hes_cloud_file"
require File.dirname(__FILE__) + "/hes_cloud_directory"
require File.dirname(__FILE__) + "/hes_cloud_storage_engine"
require File.dirname(__FILE__) + "/hes_cloud_storage_uploader_extension"
require File.dirname(__FILE__) + "/generators/hes_cloud_storage_generator"
require File.dirname(__FILE__) + "/hes_cloud_file_error"

module HesCloudStorage
  # Engine to add HES Cloud Storage to an application
  class Engine < ::Rails::Engine

    CarrierWave::Uploader::Base.storage_engines[:hes_cloud] = "HesCloudStorage::HesCloudStorageEngine"
    CarrierWave::Uploader::Base.send(:include, HesCloudStorage::HesCloudStorageUploaderExtension)
    
    initializer "hes-cloud-storage" do |app|
      CarrierWave::Uploader::Base.storage_engines[:hes_cloud] = "HesCloudStorage::HesCloudStorageEngine"
      CarrierWave::Uploader::Base.send(:include, HesCloudStorage::HesCloudStorageUploaderExtension)
    end

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end
end
