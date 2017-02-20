class Message < ActiveRecord::Base

  validates :user_id, presence: true

  belongs_to :user

  mount_uploader :image, MessagePhotoUploader

  def self.save_message(creator_id, content)
    message = Message.new
    message.user_id = creator_id
    message.content = content
    message.save
  end
end
