class ChangeHiddenAndAddAnotherToChatMessage < ActiveRecord::Migration
  def up
    change_column :chat_messages, :hidden, :boolean, :default => false
    rename_column :chat_messages, :hidden, :user_deleted
    add_column :chat_messages, :friend_deleted, :boolean, :default => false
  end

  def down
    rename_column :chat_messages, :user_deleted, :hidden
    remove_column :chat_messages, :friend_deleted
  end
end
