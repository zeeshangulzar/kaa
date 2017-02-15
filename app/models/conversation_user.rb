class ConversationUser < ActiveRecord::Base

  validates :conversation_id, :user_id, presence: true

  belongs_to :user
  belongs_to :conversation
end
