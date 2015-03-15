class ChatMessageEmail
  @queue = :default

  def self.perform(chat_message)
    ActiveRecord::Base.verify_active_connections!
    GoMailer.chat_message_email(chat_message).deliver!
  end
end
