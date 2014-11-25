# Create UDF Definitions
class CreateUdfDefs < ActiveRecord::Migration
  # Up and down for creating udf definitions table
  def change
    create_table :udf_defs, :force => true do |t|
      t.string  :owner_type,  :limit => 30
      t.string  :parent_type, :limit => 30
      t.integer :parent_id
      t.string  :data_type
      t.boolean :is_enabled, :default => true
    end

    add_index :udf_defs, [:parent_type, :parent_id], :name => :by_parent_type_parent_id
  end
end
