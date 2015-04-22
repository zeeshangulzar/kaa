class TeamMember < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :team_id, :user_id, :user, :user
  
  # Associations
  belongs_to :user
  belongs_to :team

end
