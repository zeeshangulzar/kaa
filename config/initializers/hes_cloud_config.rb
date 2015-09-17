HesCloudStorage.configuration = {
  :app_key => "PijBOCvgWhxrCYkBDGOvylaMtJXknyrY",
  :app_folder => "h4h",
  :use_ssl => Rails.env.production?,
  :domain => Rails.env.production? ? 'hesapps.com' : 'staging.hesapps.com'
}
CarrierWave.configure do |config|
      config.ensure_multipart_form = false
 end
