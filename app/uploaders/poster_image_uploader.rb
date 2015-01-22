# encoding: utf-8

class PosterImageUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick

  storage :hes_cloud

  def store_dir
    "posters/"
  end

  version :large do
    process :resize_to_fit => [100, 100]
  end

  # Create different versions of your uploaded files:
  version :small do
    process :resize_to_fit => [40, 40]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "poster-#{Time.now.to_i}.jpg" if original_filename
  end

  def default_url
    "/images/posters/" + [version_name, "default.jpg"].compact.join('_')
  end

end
