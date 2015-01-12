class Group < ApplicationModel
  attr_privacy :name, :group_users, :me
  attr_privacy_path_to_user :owner

  attr_accessible :owner_id, :owner, :name, :group_users_attributes, :group_users, :users_attributes, :users

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"

  has_many :group_users
  has_many :users, :through => :group_users
  accepts_nested_attributes_for :group_users, :users

  validates_presence_of :name

end