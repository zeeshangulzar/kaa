class ChatMessageEmail
  @queue = :default

  def self.perform(chat_message_id)
    ActiveRecord::Base.verify_active_connections!
    chat_message = ChatMessage.find(chat_message_id) rescue nil
    if chat_message
      GoMailer.chat_message_email(chat_message).deliver!
    end
  end
end
