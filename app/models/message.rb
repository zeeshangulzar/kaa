class Message < ActiveRecord::Base

  validates :user_id, presence: true

  belongs_to :user

  def self.save_message(params)
    message = Message.new
    message.user_id = params[:creator_id]
    message.content = params[:message][:content]
    message.save
  end
end
