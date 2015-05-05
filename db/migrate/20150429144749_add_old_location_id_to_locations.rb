class AddOldLocationIdToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :old_location_id, :integer
  end
end
