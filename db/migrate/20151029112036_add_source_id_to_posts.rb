class AddSourceIdToPosts < ActiveRecord::Migration
  def up
    add_column :posts, :source_id, :integer
    add_index :posts, :source_id
  end
  def down
    remove_column :posts, :source_id
  end
end
