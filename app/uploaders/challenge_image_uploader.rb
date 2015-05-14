class ChallengeImageUploader < ApplicationUploader

  def self.store_dir
    "challenges/"
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename ||= "challenge-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/challenges/" + [version_name, "default.png"].compact.join('_')
  end

end
