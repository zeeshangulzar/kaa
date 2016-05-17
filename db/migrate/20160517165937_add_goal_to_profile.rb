class AddGoalToProfile < ActiveRecord::Migration
  def up
    add_column :profiles, :goal, :text
    add_index :profiles, :user_id
  end
  def down
    remove_column :profiles, :goal
    remove_index :profiles, :user_id
  end
end
