# HesCentral allows easy access to HES' central website for recipes, contact requests, feedback, etc.
module HesCentral
  # User name for HES Central
  USER = 'hes'

  # User password for HES Central
  PASSWORD = '9BED01DAB12E6451EAEC91B1E200D80D63056D30F8C038F51F0137976DD83FBC'

  mattr_accessor :application_name
  mattr_accessor :application_repository_name
  mattr_accessor :application_domain
  mattr_accessor :application_sso_url
end

require 'hes-central/engine'
