class GroupUser < ApplicationModel
  attr_privacy_path_to_user :group, :owner
  attr_accessible :group_id, :user_id
  attr_privacy :group_id, :user_id, :me

  belongs_to :group
  accepts_nested_attributes_for :group

  belongs_to :user, :in_json => true

end