class AddTitleToPosts < ActiveRecord::Migration
  def up
    add_column :posts, :title, :string
    add_column :posts, :views, :integer, :default => 0
  end
  def down
    remove_column :posts, :title
    remove_column :posts, :views
  end
end
