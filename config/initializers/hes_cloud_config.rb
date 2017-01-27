HesCloudStorage.configuration = {
  :app_key => Rails.env.development? ? "jakebreaksbakedcakes" : "picturedmeantfunnysilence",
  :app_folder => Rails.env.development? ? "#{APPLICATION_NAME}_dev" : APPLICATION_NAME,
  :use_ssl => Rails.env.production?,
  :domain => 'hesapps.com'
}
CarrierWave.configure do |config|
      config.ensure_multipart_form = false
end
