class TeamPhotoImageUploader < ApplicationUploader

  def self.store_dir
    "team_photos/"
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename ||= "team_photo-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/team_photos/" + [version_name, "default.png"].compact.join('_')
  end

end
