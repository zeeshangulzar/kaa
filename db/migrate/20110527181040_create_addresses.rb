class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.references :contact
      t.string :address_type, :limit => 30, :default => "main"
      t.string :line1, :line2, :city, :state_province, :country, :postal_code, :limit => 150
      
      t.timestamps
    end
  end
end
