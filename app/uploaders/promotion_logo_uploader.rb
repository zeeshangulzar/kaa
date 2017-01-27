class PromotionLogoUploader < ApplicationUploader

  def self.store_dir
    "promotions/"
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename ||= "promotion-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/default/promotions/" + [version_name, "default.png"].compact.join('_')
  end

end
