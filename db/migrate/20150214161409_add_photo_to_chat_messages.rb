class AddPhotoToChatMessages < ActiveRecord::Migration
  def change
    add_column :chat_messages, :photo, :string, :length => 255, :default => nil
  end
end
