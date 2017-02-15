class CreateConversations < ActiveRecord::Migration
  def change
    create_table :conversations do |t|
      t.integer :creator_id, null: false
      t.string :conversation_type, limit: 1, default: 'g'
      t.timestamps
    end
  end
end
