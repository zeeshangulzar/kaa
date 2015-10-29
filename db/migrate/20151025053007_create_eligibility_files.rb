class CreateEligibilityFiles < ActiveRecord::Migration
  def self.up
    create_table :eligibility_files do |t|
      t.references :promotion
      t.string     :filename
      t.integer    :total_rows
      t.integer    :rows_processed
      t.string     :status
      t.timestamps
    end
  end

  def self.down
    drop_table :eligibility_files
  end
end
