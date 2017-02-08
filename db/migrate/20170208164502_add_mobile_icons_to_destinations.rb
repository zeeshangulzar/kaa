class AddMobileIconsToDestinations < ActiveRecord::Migration
  def change
    add_column :destinations, :icon1_mobile, :string, :length => 255, :default => nil
    add_column :destinations, :icon2_mobile, :string, :length => 255, :default => nil
  end
end
