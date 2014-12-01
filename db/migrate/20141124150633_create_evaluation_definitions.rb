class CreateEvaluationDefinitions < ActiveRecord::Migration
  def change
    create_table :evaluation_definitions do |t|
    	t.integer  :promotion_id
      t.string   :name
      t.integer  :days_from_start
      t.integer  :sequence
      t.text     :message
      t.text     :visible_questions
      t.integer  :flags_1, :default => 126
      t.integer  :flags_2, :default => 134096128
      t.timestamps
    end
  end
end
