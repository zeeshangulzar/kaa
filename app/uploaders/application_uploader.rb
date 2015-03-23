class ApplicationUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick

  storage :hes_cloud

  def self.asset_host_url
    return 'http://assets1.' + HesCloudStorage.configuration[:domain] + '/' + HesCloudStorage.configuration[:app_folder] + '/' + self.store_dir
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def self.extension_white_list
    %w(jpg jpeg gif png)
  end

end
