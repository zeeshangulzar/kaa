class Invite < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :event_id, :event, :invited_user_id, :user, :inviter_user_id, :inviter, :status, :any_user
  attr_accessible :event_id, :event, :invited_user_id, :user, :inviter_user_id, :inviter, :status

  STATUS = {
    :unresponded  => 0,
    :maybe        => 1,
    :yes          => 2,
    :no           => 3
  }

  belongs_to :event
  has_one :inviter, :class_name => "User", :foreign_key => :inviter_user_id
  has_one :user, :class_name => "User", :foreign_key => :invited_user_id

end