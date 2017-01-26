class AlterTeamMembers < ActiveRecord::Migration
  def up
    rename_column :team_members, :total_behavior_points, :total_promotion_behavior_points
    add_column :team_members, :total_competition_behavior_points, :integer, :default => 0
  end
  def down
    rename_column :team_members, :total_promotion_behavior_points, :total_behavior_points
    remove_column :team_members, :total_competition_behavior_points
  end
end
