
require "hes-cloud-storage/engine"

# Library to create a model that can easily talk to HesCloud application and also add StorageEngine for using with CarrierWave
module HesCloudStorage
  mattr_accessor :configuration
  
  # User name for HES Cloud service
  USER = 'hesdev'

  # Password for HES Cloud Service
  PASSWORD = 'SFdas(784d8JKaf'

  # # Domain for assets service
  # DOMAIN = "hesapps.com"

  # Subdomain for assets service
  SUBDOMAIN = "assets"

  MAX_CDN_SEQUENCE = 3
end
