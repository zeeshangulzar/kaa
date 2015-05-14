class LongTermGoalImageUploader < ApplicationUploader

  def self.store_dir
    "long_term_goals/"
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def original_filename
    @original_filename ||= "long_term_goal-#{Time.now.to_i}-#{SecureRandom.hex(16)}.png"
  end

  def default_url
    "/images/long_term_goals/" + [version_name, "default.png"].compact.join('_')
  end

end
