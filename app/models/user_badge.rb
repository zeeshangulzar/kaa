class UserBadge < ApplicationModel
  attr_accessible *column_names
  attr_privacy :user_id, :badge_id, :badge, :earned_year, :earned_date, :created_at, :updated_at, :any_user
  
  belongs_to :user
  belongs_to :badge

end
