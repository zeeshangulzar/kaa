# encoding: utf-8

class PostPhotoUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick

  storage :hes_cloud

  def store_dir
    "post_photos/"
  end

  process :resize_to_fit => [612, 612]

  # Create different versions of your uploaded files:
  version :thumbnail do
    process :resize_to_fit => [150, 150]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "post-photo-#{Time.now.to_i}.jpg" if original_filename
  end

  def default_url
    "/images/posts/" + [version_name, "default.jpg"].compact.join('_')
  end

end