class CreateExerciseActivities < ActiveRecord::Migration
  def change
    create_table :exercise_activities do |t|
      t.references :promotion
      t.string   :name
      t.text     :summary
      
      t.timestamps
    end
    add_index :exercise_activities, :promotion_id
  end
end
