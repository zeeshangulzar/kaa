class CreateEntriesTable < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.references :user
      t.boolean :is_recorded
      t.date :recorded_on
      t.text :notes
      t.integer :daily_points, :default => 0
      t.integer :gift_points, :default => 0
      t.integer :behavior_points, :default => 0
      t.integer :exercise_minutes, :default => 0
      t.integer :exercise_steps, :default => 0
      
      t.timestamps
    end
    add_index :entries, :user_id
  end
end
