class TimedActivity < ActiveRecord::Base

  belongs_to :activity
  has_many :point_thresholds, :order => 'min DESC'

  attr_accessible :begin_date, :end_date

end