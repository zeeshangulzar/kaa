HesCloudStorage.configuration = {
  :app_key => "jmrtsAnpbceYTIWdYuJKMngjGIvhMsUe",
  :app_folder => "go_kp",
  :use_ssl => Rails.env.production?,
  :domain => Rails.env.production? ? 'hesapps.com' : 'staging.hesapps.com'
}
