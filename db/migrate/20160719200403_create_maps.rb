class CreateMaps < ActiveRecord::Migration
  def self.up
    create_table :maps do |t|
      t.string :name
      t.string :summary
      t.integer :tile_size
      t.integer :min_zoom
      t.integer :max_zoom
      t.integer :adjusted_width
      t.integer :adjusted_height
      t.integer :scale_zoom
      t.integer :scaled_min_zoom
      t.integer :icon_visible_zoom
      t.integer :image_width
      t.integer :image_height
      t.string :status, :default => Map::STATUS[:inactive]
      t.timestamps
    end
  end

  def self.down
    drop_table :maps
  end
end
