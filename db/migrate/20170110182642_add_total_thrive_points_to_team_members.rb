class AddTotalThrivePointsToTeamMembers < ActiveRecord::Migration
  def up
    add_column :team_members, :total_thrive_points, :integer, :default => 0
  end
  def down
    remove_column :team_members, :total_thrive_points
  end
end
