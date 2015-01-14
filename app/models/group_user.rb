class GroupUser < ApplicationModel
  attr_privacy_path_to_user :group, :owner
  attr_accessible :group_id, :user_id
  attr_privacy :group_id, :user_id, :user, :me

  belongs_to :group
  belongs_to :user

end