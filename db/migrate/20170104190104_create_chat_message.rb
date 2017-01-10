class CreateChatMessage < ActiveRecord::Migration
  def change
    create_table :chat_messages do |t|
      t.integer   :user_id
      t.integer   :friend_id
      t.string    :message
      t.boolean   :seen
      t.timestamps
    end
  end
end
