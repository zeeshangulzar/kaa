class CreateFriendships < ActiveRecord::Migration
  def up
    create_table :friendships do |t|
      t.integer :friendee_id
      t.integer :friender_id
      t.string :status, :limit => 1, :default => 'P'
      t.string :friend_email
      t.integer :sender_id
      t.text :message
      t.timestamps
    end

    add_index :friendships, [:friender_id]
    add_index :friendships, [:friendee_id]
    add_index :friendships, [:friender_id, :friendee_id], :unique => true, :name => 'by_friender_and_friendee_id'
    add_index :friendships, [:friendee_id, :friender_id], :unique => true, :name => 'by_friendee_and_friender_id'
  end

  def down
    remove_table :friendships
  end

end
