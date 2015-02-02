class RemoveTypesFromFriendships < ActiveRecord::Migration
  def up
    remove_column :friendships, :friendee_type
    remove_column :friendships, :friender_type
    remove_column :friendships, :sender_type
  end

  def down
    add_column :friendships, :friendee_type, :integer, :default => "User"
    add_column :friendships, :friender_type, :integer, :default => "User"
    add_column :friendships, :sender_type, :integer, :default => "User"
    add_index :friendships, [:friender_type, :friender_id], :name => "friender_idx"
    add_index :friendships, [:friendee_type, :friendee_id], :name => "friendee_idx"
    add_index :friendships, [:sender_type, :sender_id], :name => "friendship_sender_idx"
  end
end
