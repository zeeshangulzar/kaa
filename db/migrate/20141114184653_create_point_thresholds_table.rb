class CreatePointThresholdsTable < ActiveRecord::Migration
  def change
    create_table :point_thresholds do |t|
      t.references :activity, :timed_activity
      t.integer :value
      t.integer :min

      t.timestamps
    end   
  end
end