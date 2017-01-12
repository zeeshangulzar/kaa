class PointThreshold < ApplicationModel

  belongs_to :pointable, :polymorphic => true
  belongs_to :promotion
  attr_privacy_no_path_to_user
  attr_accessible :min, :value, :name, :pointable_type, :pointable_id, :promotion_id
  attr_privacy :min, :value, :name, :public

end