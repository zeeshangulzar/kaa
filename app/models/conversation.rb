class Conversation < ActiveRecord::Base

  CONVERSATION_TYPES = { 'g' => 'general', 't' => 'team' }

  validates :creator_id, presence: true

  belongs_to :user, foreign_key: :creator_id
  belongs_to :conversation_users

  def self.create_conversation(params)
    begin
      ActiveRecord::Base.transaction do
        conversation = save_conversation(params)
        conversation.save_conversation_users(params)
        Message.save_message(params[:creator_id], params[:message][:content])
      end
      return true
    rescue
      return false
    end
  end

    def self.save_conversation(params)
      conversation = Conversation.new
      conversation.creator_id = params[:creator_id]
      conversation.conversation_type = params[:conversation_type]
      conversation.save
      conversation
    end

    def save_conversation_users(params)
      return if params[:recipients].blank?
      params[:recipients].each do |receipient|
        conversation_user = ConversationUser.new
        conversation_user.conversation = self
        conversation_user.user_id = receipient
        conversation_user.save
      end
    end

end
