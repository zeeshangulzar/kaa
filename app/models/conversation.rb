class Conversation < ActiveRecord::Base

  CONVERSATION_TYPES = { 'g' => 'general', 't' => 'team' }

  validates :creator_id, presence: true

  belongs_to :user, foreign_key: :creator_id
  has_many :conversation_users

  scope :unmuted_conversations, ->(creator_id) {includes(:conversation_users).where("conversation_users.muted_at IS NOT NULL AND conversations.creator_id = ?", creator_id)}

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

    def syncronize_conversation_users
      #Under the assumption, conversatuion has polymorphic assocation with team
      user_ids = []
      users = self.conversation_users
      members = self.team.members
      members.each do |member|
        user = users.where(user_id: member.user_id).last
        if user.blank?
          new_user = self.conversation_user.new
          new_user.user_id = member.user_id
          new_user.save
          user_ids << member.user_id
        end
      end
      rejected_users = users.where("user_id NOT IN (?)", user_ids).delete_all
    end

end
