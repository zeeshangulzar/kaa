class CreateTimedActivitiesTable < ActiveRecord::Migration
  def change
    create_table :timed_activities do |t|
      t.references :activity
      t.date :begin_date
      t.date :end_date

      t.timestamps
    end   
  end
end
