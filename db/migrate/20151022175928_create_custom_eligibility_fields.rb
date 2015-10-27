class CreateCustomEligibilityFields < ActiveRecord::Migration
  def self.up
    create_table :custom_eligibility_fields do |t|
      t.references :promotion
      t.string :name,           :limit => 50
      t.string :data_type,      :limit => 50
      t.integer :sequence
      t.integer :file_position, :integer
      t.boolean :is_deleted,    :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :custom_eligibility_fields
  end
end
