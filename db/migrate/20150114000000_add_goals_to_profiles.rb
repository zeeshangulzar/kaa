class AddGoalsToProfiles < ActiveRecord::Migration
  def change
    remove_column :profiles, :daily_goal
    add_column :profiles, :goal_steps, :integer
    add_column :profiles, :goal_minutes, :integer
  end
end
