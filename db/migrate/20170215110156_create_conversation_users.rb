class CreateConversationUsers < ActiveRecord::Migration
  def change
    create_table :conversation_users do |t|
      t.references :user, :conversation, null: false
      t.datetime   :joined_at, default: Time.now
      t.datetime   :muted_at
      t.datetime   :last_read_at
      t.datetime   :last_seen_at
      t.timestamps
    end
  end
end
