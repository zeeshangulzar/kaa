class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.integer   :promotion_id
      t.string    :name
      t.integer   :sequence
      t.integer   :root_location_id
      t.integer   :parent_location_id
      t.integer   :depth
      t.timestamps
    end
  end
end