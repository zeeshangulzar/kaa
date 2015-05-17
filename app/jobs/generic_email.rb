class GenericEmail
  @queue = :default

  def self.perform(emails, subject, message, from_id = nil)
    ActiveRecord::Base.verify_active_connections!
    from = User.find(from_id) rescue nil
    GoMailer.generic_email(emails, subject, message, from).deliver!
  end
end
