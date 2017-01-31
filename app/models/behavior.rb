class Behavior < ApplicationModel
  attr_accessible :promotion_id, :behaviorable_type, :behaviorable_id, :name, :content, :summary, :sequence, :image, :start, :end, :visible_start, :visible_end, :created_at, :updated_at
  attr_privacy_no_path_to_user
  attr_privacy :name, :content, :summary, :image, :sequence, :start, :end, :visible_start, :visible_end, :public

  belongs_to :promotion
  belongs_to :behaviorable

  
  has_many :point_thresholds, :as => :pointable, :order => "min ASC"

  # Name, type of prompt and sequence are all required
  validates_presence_of :name, :summary
  
  scope :visible, where("CURDATE() BETWEEN `competition_behaviors`.`visible_start` AND `competition_behaviors`.`visible_end`")
  scope :recordable, where("CURDATE() BETWEEN `competition_behaviors`.`start` AND `competition_behaviors`.`end`")

  def visible
    return self.promotion.current_date.between?(self.visible_start, self.visible_end)
  end

  def recordable
    return self.promotion.current_date.between?(self.start, self.end)
  end

end
