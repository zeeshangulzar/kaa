class CreateRoutes < ActiveRecord::Migration
  def self.up
    create_table :routes do |t|
      t.references  :map
      t.string :name
      t.string :travel_type
      t.string :status, :default => 'inactive'
      t.integer :length
      t.text :points
      t.text :ordered_destinations
      t.string :overlay_image
      t.timestamps
    end
  end

  def self.down
    drop_table :routes
  end
end
