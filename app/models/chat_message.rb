class ChatMessage < ActiveRecord::Base
  attr_accessible :message, :friend_id, :user_id
  attr_privacy :message, :user_id, :friend_id, :seen, :created_at, :updated_at, :any_user
  attr_privacy_no_path_to_user

  has_one :user
  has_one :friend, :class_name => "User", :foreign_key => "friend_id"

end