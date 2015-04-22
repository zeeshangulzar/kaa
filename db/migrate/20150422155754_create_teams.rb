class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table :teams do |t|
      t.references :competition
      t.string :name, :limit => 40
      t.string :motto
      t.integer :status, :default => 0

      t.timestamps
    end
    add_index :teams, [:competition_id,:status], :name => 'by_competition_id_and_status'
  end

  def self.down
    drop_table :teams
  end
end
