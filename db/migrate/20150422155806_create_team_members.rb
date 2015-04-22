class CreateTeamMembers < ActiveRecord::Migration
  def self.up
    create_table :team_members do |t|
      t.references :team, :user, :competition
      t.boolean :is_leader
      t.timestamps
    end
    add_index :team_members, :team_id, :name=>'by_team_id'
    add_index :team_members, :user_id, :name=>'by_user_id'
  end
  def self.down
    drop_table :team_members
  end
end