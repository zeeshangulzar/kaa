class Group < ApplicationModel
  attr_privacy :name, :users, :me
  attr_privacy_path_to_user :owner

  attr_accessible :owner_id, :name, :group_users_attributes, :users_attributes

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"

  has_many :group_users
  has_many :users, :through => :group_users, :in_json => true
  accepts_nested_attributes_for :group_users

  validates_presence_of :name


  # Overrides serializable_hash so that only questions that are turned on are returned
  #def serializable_hash(options = {})
 # 	hash = super
 #   hash[:users] = self.users.collect{|x|x.id}
 #   return hash
 # end

end