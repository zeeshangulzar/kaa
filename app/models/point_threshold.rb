class PointThreshold < ActiveRecord::Base

  belongs_to :activity
  belongs_to :timed_activity

  attr_accessible :min, :value

end