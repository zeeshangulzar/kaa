class AddGoalPointsToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :goal_points, :integer
  end
end
