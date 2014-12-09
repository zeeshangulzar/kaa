class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.integer :friendee_id
      t.string :friendee_type
      t.integer :friender_id
      t.string :friender_type
      t.string :status, :limit => 1, :default => 'P'
      t.string :friend_email
      t.integer :sender_id
      t.string :sender_type

      t.timestamps
    end

    add_index :friendships, [:friender_type, :friender_id], :name => "friender_idx"
    add_index :friendships, [:friendee_type, :friendee_id], :name => "friendee_idx"
    add_index :friendships, [:sender_type, :sender_id], :name => "friendship_sender_idx"
  end
end
