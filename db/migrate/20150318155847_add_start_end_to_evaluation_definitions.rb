class AddStartEndToEvaluationDefinitions < ActiveRecord::Migration
  def change
    add_column :evaluation_definitions, :start_date, :date
    add_column :evaluation_definitions, :end_date, :date
  end
end
