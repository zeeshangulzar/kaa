class AlterTeamMembers < ActiveRecord::Migration
  def up
    rename_column :team_members, :total_behavior_points, :total_promotion_behavior_points
  end
  def down
    rename_column :team_members, :total_promotion_behavior_points, :total_behavior_points
  end
end
