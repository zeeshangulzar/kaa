class ContentEmail
  @queue = :default

  def self.perform(model, object, emails, user_id, message)
    # TODO: this is broken because you have to pass ids and
    # instantiate the objects here because if you pass the objects
    # they are all converted to hashes and lose their methods and everything sucks
    ActiveRecord::Base.verify_active_connections!
    user = User.find(user_id)
    GoMailer.content_email(model, object, emails, user, message).deliver!
  end
end
