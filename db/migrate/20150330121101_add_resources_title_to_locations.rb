class AddResourcesTitleToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :resources_title, :string
    add_column :promotions, :resources_title, :string, :default => 'Resources'
  end
end
