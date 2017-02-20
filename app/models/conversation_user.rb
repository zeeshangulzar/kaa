class ConversationUser < ActiveRecord::Base

  validates :conversation_id, :user_id, presence: true

  belongs_to :user
  belongs_to :conversation

  scope :last_read_users, ->(user_id) { where(user_id: user_id).order('last_read_at DESC') }

  def self.update_last_seen(user_id)
    conversation_users = self.last_read_users(user_id)
    conversation_users.each do |user|
      user.last_seen_at = user.last_read_at
      user.save
    end
  end

end
