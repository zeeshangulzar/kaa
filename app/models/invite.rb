class Invite < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :invited_user_id, :inviter_user_id, :status, :any_user
  attr_accessible :event_id, :invited_user_id, :inviter_user_id, :status

  STATUS = {
    :unresponded  => 0,
    :maybe        => 1,
    :yes          => 2,
    :no           => 3
  }
  
  belongs_to :event
  belongs_to :inviter, :class_name => "User", :foreign_key => "inviter_user_id"
  belongs_to :user, :class_name => "User", :foreign_key => "invited_user_id", :in_json => true

  before_create :set_default_values

  def set_default_values
    self.status ||= Invite::STATUS[:unresponded]
  end

end