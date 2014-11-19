class PointThreshold < ActiveRecord::Base

  belongs_to :pointable, :polymorphic => true

  attr_accessible :min, :value

end