class CreateTimedBehaviorsTable < ActiveRecord::Migration
  def change
    create_table :timed_behaviors do |t|
      t.references :behavior
      t.date :begin_date
      t.date :end_date

      t.timestamps
    end   
  end
end
