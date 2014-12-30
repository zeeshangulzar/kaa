module HesCentral
  # Central Resource Base class
  class CentralResource < ActiveResource::Base
    self.site = Rails.env.development? || Rails.env.test? || (defined?(IS_STAGING) && IS_STAGING) ? "http://dashboard.staging.hesapps.com" : "http://dashboard.hesapps.com"
    self.user = HesCentral::USER
    self.password = HesCentral::PASSWORD
    self.format = :xml
    self.include_root_in_json = false

    # Overrides the save method to set the app name before a save
    def save(*args)
      if @new_record && !self.is_?(App)
        self.app_name = HesCentral.application_repository_name
      end
      super(*args)
    end

    # Overrides the create method to set the app name before a create
    def create(*args)
      if !self.is_?(App)
        self.app_name = HesCentral.application_repository_name
      end
      
      super(*args)
    end
  end
end