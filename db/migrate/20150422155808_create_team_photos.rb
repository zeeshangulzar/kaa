class CreateTeamPhotos < ActiveRecord::Migration
  def self.up
    create_table :team_photos do |t|
      t.references :team, :user
      t.string :image
      t.timestamps
    end
    add_index :team_photos, :team_id, :name=>'by_team_id'
    add_index :team_photos, :user_id, :name=>'by_user_id'
  end
  def self.down
    drop_table :team_photos
  end
end