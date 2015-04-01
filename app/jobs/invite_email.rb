class InviteEmail
  @queue = :default

  def self.perform(emails, user_id, message = nil)
    user = User.find(user_id)
    GoMailer.invite_email(emails, user, message).deliver!
  end
end
