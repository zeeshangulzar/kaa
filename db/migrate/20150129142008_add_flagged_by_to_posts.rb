class AddFlaggedByToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :flagged_by, :integer
  end
end
