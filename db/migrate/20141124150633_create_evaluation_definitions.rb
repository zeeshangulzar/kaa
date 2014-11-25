class CreateEvaluationDefinitions < ActiveRecord::Migration
  def change
    create_table :evaluation_definitions do |t|
    	t.integer  :eval_definitionable_id
    	t.string   :eval_definitionable_type
      t.string   :name
      t.integer  :days_from_start
      t.integer  :sequence
      t.text     :message
      t.text     :visible_questions
      t.integer  :flags_1, :default => 126
      t.integer  :flags_2, :default => 134096128
      t.timestamps
    end

    add_index :evaluation_definitions, [:eval_definitionable_id, :eval_definitionable_type], :name => :eval_def_idx
  end
end
