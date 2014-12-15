class TimedBehavior < ApplicationModel

  belongs_to :behavior
  has_many :point_thresholds, :as => :pointable, :order => 'min DESC'

  attr_accessible :begin_date, :end_date

end