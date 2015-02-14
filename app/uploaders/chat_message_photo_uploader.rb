# encoding: utf-8

class ChatMessagePhotoUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick

  storage :hes_cloud

  def store_dir
    "messages/"
  end

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
  def original_filename
    @original_filename = "message-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/messages/" + [version_name, "default.png"].compact.join('_')
  end

end
