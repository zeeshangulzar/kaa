class AlterMaps < ActiveRecord::Migration
  def up
    add_column :maps, :settings, :text
    add_column :maps, :image_dir, :text
    Map.all.each{|map|
      map.set_defaults
      map.settings = {
        :tile_size         => map.tile_size,
        :min_zoom          => map.min_zoom,
        :max_zoom          => map.max_zoom,
        :adjusted_width    => map.adjusted_width,
        :adjusted_height   => map.adjusted_height,
        :scale_zoom        => map.scale_zoom,
        :scaled_min_zoom   => map.scaled_min_zoom,
        :icon_visible_zoom => map.icon_visible_zoom,
        :image_width       => map.image_width,
        :image_height      => map.image_height
      }.to_json
      map.save!
    }
    remove_column :maps, :tile_size
    remove_column :maps, :min_zoom
    remove_column :maps, :max_zoom
    remove_column :maps, :adjusted_width
    remove_column :maps, :adjusted_height
    remove_column :maps, :scale_zoom
    remove_column :maps, :scaled_min_zoom
    remove_column :maps, :icon_visible_zoom
    remove_column :maps, :image_width
    remove_column :maps, :image_height
  end
end
