class EventInviteEmail
  @queue = :default

  def self.perform(event_id, user_id)
    event = Event.find(event_id)
    user = User.find(user_id)
    GoMailer.event_invite_email(event, user).deliver!
  end
end
