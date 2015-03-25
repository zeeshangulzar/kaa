class AddLogoToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :logo, :text
  end
end
