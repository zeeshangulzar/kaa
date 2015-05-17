class CreateTeamInvites < ActiveRecord::Migration
  def self.up
    create_table :team_invites do |t|
      t.references :team, :user, :competition
      t.string :status, :limit => 1
      t.string :invite_type, :limit => 1
      t.string :email
      t.integer :invited_by
      t.string :message
      t.timestamps
    end
    add_index :team_invites, :team_id, :name=>'by_team_id'
    add_index :team_invites, :user_id, :name=>'by_user_id'
  end
  def self.down
    drop_table :team_invites
  end
end