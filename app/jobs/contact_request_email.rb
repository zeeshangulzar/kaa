class ContactRequestEmail
  @queue = :default

  def self.perform(contact_request)
    ActiveRecord::Base.verify_active_connections!
    GoMailer.contact_request_email(contact_request).deliver!
  end
end
