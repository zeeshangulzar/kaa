class CreateEntriesTable < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.references :user
      t.boolean :is_recorded
      t.date :recorded_on
      t.text :notes
      t.integer :daily_points
      t.integer :gift_points
      t.integer :behavior_points
      t.integer :exercise_minutes
      t.integer :exercise_steps
      
      t.timestamps
    end
    add_index :entries, :user_id
  end
end
