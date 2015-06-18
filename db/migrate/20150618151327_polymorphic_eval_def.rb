class PolymorphicEvalDef < ActiveRecord::Migration
  def change
    add_column :evaluation_definitions, :eval_definitionable_type, :string
    add_column :evaluation_definitions, :eval_definitionable_id, :integer
  end
end
