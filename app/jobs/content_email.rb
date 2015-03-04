class ContentEmail
  @queue = :default

  def self.perform(model, object, emails, user_id, message)
    user = User.find(user_id)
    GoMailer.content_email(model, object, emails, user, message).deliver!
  end
end
