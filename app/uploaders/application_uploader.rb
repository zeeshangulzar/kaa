class ApplicationUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick

  storage :hes_cloud

  def self.asset_host_url
    return 'http://assets1.' + HesCloudStorage.configuration[:domain] + '/' + HesCloudStorage.configuration[:app_folder] + '/' + self.store_dir
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename = "profile-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/users/" + [version_name, "default.png"].compact.join('_')
  end

end
