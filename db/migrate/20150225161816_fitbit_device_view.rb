class FitbitDeviceView < ActiveRecord::Migration
  def self.up
    execute "create view fitbit_user_devices as select * from fbskeleton.fitbit_user_devices_view"
 end

  def self.down
  end
end