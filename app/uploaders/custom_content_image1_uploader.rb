class CustomContentImage1Uploader < ApplicationUploader

  def self.store_dir
    "custom_content/"
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename ||= "custom_content-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/custom_content/" + [version_name, "default.png"].compact.join('_')
  end

end
