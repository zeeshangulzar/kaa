class TeamInvite < ApplicationModel

  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :team_id, :user_id, :competition_id, :invite_type, :status, :email, :any_user

end