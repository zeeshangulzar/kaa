# Create owner udf table
class CreateEvaluationUdfs < ActiveRecord::Migration
  def change
    create_table :evaluation_udfs, :force => true do |t|
      t.column :evaluation_id, :integer
    end

    connection.add_index :evaluation_udfs, :evaluation_id, :name => :by_evaluation_id
  end
end
