class DeviceFields < ActiveRecord::Migration
  def up
    add_column :users, :active_device, :string
    
    add_column :entries, :manually_recorded, :boolean

    execute "update entries set manually_recorded = 1"
  end

  def down
    remove_column :entries, :manually_recorded
    
    remove_column :users, :active_device
  end
end
