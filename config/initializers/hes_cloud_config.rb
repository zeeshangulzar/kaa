HesCloudStorage.configuration = {
  :app_key => "PijBOCvgWhxrCYkBDGOvylaMtJXknyrY",
  :app_folder => APPLICATION_NAME,
  :use_ssl => Rails.env.production?,
  :domain => Rails.env.production? ? 'hesapps.com' : 'staging.hesapps.com'
}
CarrierWave.configure do |config|
      config.ensure_multipart_form = false
 end
