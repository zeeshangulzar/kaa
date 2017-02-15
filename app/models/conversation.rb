class Conversation < ActiveRecord::Base

  CONVERSATION_TYPES = { 'g' => 'general', 't' => 'team' }

  validates :creator_id, presence: true

  belongs_to :user, foreign_key: :creator_id
  belongs_to :conversation_users
end
