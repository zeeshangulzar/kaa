class CreateEntryGiftsTable < ActiveRecord::Migration
  # Create entry gifts table and indices
  def change
    create_table :entry_gifts do |t|
      t.references :entry, :gift
      t.string :value
      t.integer :sequence, :default => 0
      t.timestamps
    end
    
    add_index :entry_gifts, :entry_id
    add_index :entry_gifts, :gift_id
    add_index :entry_gifts, [:entry_id, :gift_id, :sequence], :unique => true
  end
end
