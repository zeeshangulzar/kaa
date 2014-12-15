class CreateEntryBehaviorsTable < ActiveRecord::Migration
  # Create entry behaviors table and indices
  def change
    create_table :entry_behaviors do |t|
      t.references :entry, :behavior
      t.string :value
      t.integer :sequence, :default => 0
      t.timestamps
    end
    
    add_index :entry_behaviors, :entry_id
    add_index :entry_behaviors, :behavior_id
    add_index :entry_behaviors, [:entry_id, :behavior_id, :sequence], :unique => true
  end
end
