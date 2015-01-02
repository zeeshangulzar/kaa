class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.integer :parent_post_id
      t.integer :root_post_id
      t.references :user
      t.integer :depth, :default => 0
      t.text :content, :length => 500
      t.integer :postable_id
      t.string :postable_type, :length => 20
      t.integer :wallable_id
      t.string :wallable_type, :length => 20
      t.boolean :is_flagged, :default => false
      t.boolean :is_deleted, :default => false
      t.text :photo, :length => 255

      t.timestamps
    end
    
    add_index :posts, :user_id
    add_index :posts, [:postable_type, :postable_id], :name => :postable_idx
    add_index :posts, [:wallable_type, :wallable_id], :name => :wallable_idx
    add_index :posts, :parent_post_id
    add_index :posts, :root_post_id
  end
end
