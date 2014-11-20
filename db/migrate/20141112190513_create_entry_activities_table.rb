class CreateEntryActivitiesTable < ActiveRecord::Migration
  # Create entry recording activities table and indices
  def change
    create_table :entry_activities do |t|
      t.references :entry, :activity
      t.string :value
      t.integer :sequence, :default => 0
      t.timestamps
    end
    
    add_index :entry_activities, :entry_id
    add_index :entry_activities, :activity_id
    add_index :entry_activities, [:entry_id, :activity_id, :sequence], :unique => true
  end
end
