# encoding: utf-8

class EventPhotoUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick

  storage :hes_cloud

  def store_dir
    "events/"
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename = "event-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
    return @original_filename
  end

  def default_url
    "/images/events/" + [version_name, "default.png"].compact.join('_')
  end

end
