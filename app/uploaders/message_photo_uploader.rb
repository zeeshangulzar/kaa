class MessagePhotoUploader < ApplicationUploader

  def self.store_dir
    return "messages/"
  end

  # Create different versions of your uploaded files:
  version :thumbnail do
    process :resize_to_fit => [40, 40]
  end

  process :resize_to_fit => [150, 150]

  def original_filename
    @original_filename ||= "profile-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

 # we need to place the default image at following location
  def default_url
    "/images/messages/" + [version_name, "default.png"].compact.join('_')
  end

end
