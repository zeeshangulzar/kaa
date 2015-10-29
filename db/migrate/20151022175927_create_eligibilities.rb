class CreateEligibilities < ActiveRecord::Migration
  def self.up
    # eligibilities
    create_table :eligibilities do |t|
      t.references :promotion, :user
      t.string :identifier, :limit => 100
      t.string :email, :limit => 100
      t.string :first_name, :limit => 50
      t.string :last_name, :limit => 50
      t.timestamps
    end
    # eligibilities index for identifier
    add_index :eligibilities, :identifier
  end

  def self.down
    remove_index :eligibilities, :identifier
    drop_table :eligibilities
  end
end
