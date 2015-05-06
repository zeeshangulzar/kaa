class TeamPhoto < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :team_id, :user_id, :image, :user
  
  belongs_to :team
  belongs_to :user

  mount_uploader :image, TeamPhotoImageUploader

end
