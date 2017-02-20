class ConversationTypeIdIntoConversation < ActiveRecord::Migration
  def change
    add_column :conversations, :conversation_type_id, :integer
  end
end
