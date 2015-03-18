class AddColsToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :find_out, :string
    add_column :evaluations, :liked_most_gokp, :text
    add_column :evaluations, :liked_least_gokp, :text
    add_column :evaluations, :change_one_thing, :text
    add_column :evaluations, :average_days_active_per_week, :integer
    add_column :evaluations, :average_minutes_per_day, :integer
    add_column :evaluations, :focus, :string
  end
end
