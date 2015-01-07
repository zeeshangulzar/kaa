class Invite < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :invited_user_id, :invited_group_id, :inviter_user_id, :status, :any_user
  attr_accessible :event_id, :invited_user_id, :invited_group_id, :inviter_user_id, :status

  STATUS = {
    :unresponded  => 0,
    :maybe        => 1,
    :attending    => 2,
    :declined     => 3
  }
  
  belongs_to :event
  belongs_to :inviter, :class_name => "User", :foreign_key => "inviter_user_id"
  belongs_to :user, :class_name => "User", :foreign_key => "invited_user_id", :in_json => true

  before_create :set_default_values

  def set_default_values
    self.status ||= Invite::STATUS[:unresponded]
  end

  validate :we_are_friends
  def we_are_friends
    if self.inviter.user? && !self.inviter.friends.include?(self.user)
      errors.add(:base, "You can only invite your friends to events.")
      return false
    end
    return true
  end

  validate :status_valid
  def status_valid
    if !Invite::STATUS.values.include?(self.status.to_i)
      errors.add(:base, "Invalid status")
      return false
    end
    return true
  end

  # TODO: temporary..
  def as_json(options = nil)
    return AM_as_json(options)
  end


end