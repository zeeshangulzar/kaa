class GroupUser < ApplicationModel
  attr_privacy_no_path_to_user
  attr_accessible :group_id, :user_id

  belongs_to :group
  accepts_nested_attributes_for :group

  belongs_to :user

end