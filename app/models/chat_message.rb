class ChatMessage < ApplicationModel
  attr_accessible *column_names
  attr_privacy :message, :user_id, :friend_id, :seen, :created_at, :updated_at, :friend, :user, :any_user
  attr_privacy_no_path_to_user

  belongs_to :user
  belongs_to :friend, :class_name => "User", :foreign_key => "friend_id"

  def self.by_userid(userid)
    where("user_id = :userid OR friend_id = :userid", :userid => userid).order(:created_at)
  end

  before_create :set_default_values

  def set_default_values
    self.seen ||= false
    nil
  end

end