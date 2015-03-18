class AddColsToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :find_out, :string
    add_column :evaluations, :liked_most_gokp, :text
    add_column :evaluations, :liked_least_gokp, :text
    add_column :evaluations, :change_one_thing, :text
  end
end
