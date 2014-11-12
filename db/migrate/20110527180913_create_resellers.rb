class CreateResellers < ActiveRecord::Migration
  def change
    create_table :resellers do |t|
      t.string :name, :limit => 100
      t.string :contact_name, :limit => 100
      t.string :contact_email, :limit => 100

      t.timestamps
    end
  end
end
