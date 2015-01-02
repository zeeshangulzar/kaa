# Likes migration
class CreateLikes < ActiveRecord::Migration
  # create/drop likes table
  def change
    create_table :likes do |t|
      t.integer   :user_id
      t.integer   :likeable_id
      t.string    :likeable_type,       :limit => 50
      
      t.timestamps
    end

    add_index :likes, :user_id
    add_index :likes, [:likeable_type, :likeable_id], :name => :likeable_idx
  end
end