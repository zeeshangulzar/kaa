class CreateTeamMembers < ActiveRecord::Migration
  def self.up
    create_table :team_members do |t|
      t.references :team, :user, :competition
      t.boolean :is_leader
      t.integer :total_points, :default => 0
      t.integer :total_exercise_points, :default => 0
      t.integer :total_behavior_points, :default => 0
      t.integer :total_gift_points, :default => 0
      t.timestamps
    end
    add_index :team_members, :team_id, :name=>'by_team_id'
    add_index :team_members, :user_id, :name=>'by_user_id'
  end
  def self.down
    drop_table :team_members
  end
end