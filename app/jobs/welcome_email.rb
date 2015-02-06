class WelcomeEmail
  @queue = :default

  def self.perform(user_id)
    user = User.find(user_id)
    GoMailer.welcome_email(user).deliver!
  end
end
