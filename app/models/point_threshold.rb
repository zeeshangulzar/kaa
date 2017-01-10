class PointThreshold < ApplicationModel

  belongs_to :pointable, :polymorphic => true
  attr_privacy_no_path_to_user
  attr_accessible :min, :value, :rel, :color, :name

  attr_privacy :min, :value, :color, :name, :public

end