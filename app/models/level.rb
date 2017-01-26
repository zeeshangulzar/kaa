class Level < ApplicationModel
  belongs_to :promotion
  attr_privacy_no_path_to_user
  attr_accessible :name, :promotion_id, :min, :image
  attr_privacy :name, :image, :public
  
  def self.entry_level(entry)
    level = entry.user.promotion.levels.where("`min` <= #{entry.exercise_points} and `has_logged` = #{entry.is_recorded ? 1 : 0}").last rescue nil
    return level.nil? ? "empty" : level.name
  end

end