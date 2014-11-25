class CreateCustomPrompts < ActiveRecord::Migration
  def change
    create_table :custom_prompts do |t|
      t.integer :custom_promptable_id
      t.string :custom_promptable_type
      t.integer :sequence
      t.string :prompt, :limit => 500
      t.string :data_type, :type_of_prompt, :short_label, :limit => 20
      t.text :options
      t.boolean :is_active, :default => true
      t.boolean :is_required, :default => false

      t.timestamps
    end

    add_index :custom_prompts, [:custom_promptable_type, :custom_promptable_id], :name => :cp_index
  end
end
