class UserBadge < ApplicationModel
  attr_accessible :user_id, :badge_id, :earned_year, :earned_date, :created_at, :updated_at
  attr_privacy :user_id, :badge_id, :badge, :earned_year, :earned_date, :created_at, :updated_at, :any_user
  
  belongs_to :user
  belongs_to :badge

  after_create :send_notification
  after_commit :do_badges

  acts_as_notifier

end
