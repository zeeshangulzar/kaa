class Group < ApplicationModel
  attr_privacy :name, :me
  attr_privacy_no_path_to_user

  attr_accessible :owner_id, :name, :group_users_attributes

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"

  has_many :group_users
  has_many :users, :through => :group_users
  accepts_nested_attributes_for :group_users

  

end