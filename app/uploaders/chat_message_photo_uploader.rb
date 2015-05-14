class ChatMessagePhotoUploader < ApplicationUploader

  def self.store_dir
    "messages/"
  end

  # Create different versions of your uploaded files:
  version :thumbnail do
    process :resize_to_fit => [150, 150]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename ||= "message-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/messages/" + [version_name, "default.png"].compact.join('_')
  end

end
