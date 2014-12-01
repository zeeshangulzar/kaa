class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.integer   :user_id
      t.string    :gender,                            :limit => 1
      t.integer   :daily_goal
      t.string    :first_name, :last_name,            :limit => 100
      t.string    :phone,                             :limit => 30
      t.string    :mobile_phone,                      :limit => 11
      t.string    :line1, :line2, :city, :state_province, :country, :postal_code, :limit => 150
      t.string    :time_zone
      t.string    :employee_group, :employee_entity,  :limit => 50
      t.date      :started_on, :registered_on
      t.timestamps
    end
  end
end
