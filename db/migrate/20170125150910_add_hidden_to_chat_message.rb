class AddHiddenToChatMessage < ActiveRecord::Migration
  def up
    add_column :chat_messages, :hidden, :boolean
  end
  def down
    remove_column :chat_message, :hidden, :boolean
  end
end
