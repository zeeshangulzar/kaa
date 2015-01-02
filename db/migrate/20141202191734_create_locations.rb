class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.integer     :promotion_id
      t.string      :name,                :length => 100
      t.integer     :sequence,            :default => 0
      t.integer     :parent_location_id
      t.integer     :root_location_id
      t.text        :content
      t.integer     :has_content
      t.timestamps
    end
  end
end