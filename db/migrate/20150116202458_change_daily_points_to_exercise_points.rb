class ChangeDailyPointsToExercisePoints < ActiveRecord::Migration
  def up
    rename_column :entries, :daily_points, :exercise_points
  end

  def down
    rename_column :entries, :exercise_points, :daily_points
  end
end
