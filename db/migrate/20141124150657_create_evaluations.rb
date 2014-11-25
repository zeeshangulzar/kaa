class CreateEvaluations < ActiveRecord::Migration
  def change
    drop_table :evaluations rescue nil

    create_table :evaluations do |t|
    	t.references  :user, :evaluation_definition

    	t.integer :days_active_per_week
      t.integer :fruit_servings
      t.integer :vegetable_servings
      t.integer :fruit_vegetable_servings
      t.integer :whole_grains
      t.integer :breakfast
      t.string  :stress, :limit => 9
      t.string  :sleep_hours, :limit => 11
      t.string  :social, :limit => 9
      t.integer :water_glasses
      t.text    :liked_most, :limit => 250
      t.integer :kindness
      t.string  :energy, :limit => 16
      t.string  :overall_health, :limit => 9
      t.text    :liked_least, :limit => 250
      t.string  :exercise_per_day
      t.string  :perception

      t.timestamps
    end

    add_index :evaluations, :user_id
    add_index :evaluations, :evaluation_definition_id
  end
end
