class AddColsToEvaluationsAgain < ActiveRecord::Migration
  def change
	add_column :evaluations, :sugar_beverages, :integer
	add_column :evaluations, :snack_after_dinner, :integer
  end
end
