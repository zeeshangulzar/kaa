class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.integer   :contactable_id
      t.string    :contactable_type,               :limit => 50
      t.string    :first_name, :last_name, :email, :limit => 100
      t.string    :phone,                          :limit => 30
      t.string    :mobile_phone,                   :limit => 11

      t.timestamps
    end
  end
end
