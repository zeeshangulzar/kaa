class TipFullImageUploader < ApplicationUploader

  def self.store_dir
    "tips/"
  end

  # Create different versions of your uploaded files:
  version :thumbnail do
    process :resize_to_fit => [40, 40]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename = "tip_full_image-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/tips/full_image_" + [version_name, "default.png"].compact.join('_')
  end

end
