class Map < ApplicationModel
  attr_privacy :id, :name, :summary, :status, :settings, :public
  attr_privacy_no_path_to_user
  attr_accessible *column_names

  many_to_many :with => :promotion, :primary => :promotion, :order => "id ASC", :allow_duplicates => false

  has_many :routes
  has_many :destinations

  # TODO: do these make sense?
  STATUS = {
    :inactive => 'inactive',
    :active   => 'active',
    :deleted  => 'deleted'
  }
  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end
  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  def settings
    return {
      :image_dir         => self.image_dir,
      :tile_size         => self.tile_size,
      :min_zoom          => self.min_zoom,
      :max_zoom          => self.max_zoom,
      :adjusted_width    => self.adjusted_width,
      :adjusted_height   => self.adjusted_height,
      :scale_zoom        => self.scale_zoom,
      :scaled_min_zoom   => self.scaled_min_zoom,
      :icon_visible_zoom => self.icon_visible_zoom,
      :image_width       => self.image_width,
      :image_height      => self.image_height
    }
  end

  def image_dir
    # TODO: make this do things
    return "/images/default/map/map_detailed"
  end

  def destroy
    # TODO: we want to do a soft delete, so figure out what this should do...
    self.status = STATUS[:deleted]
    self.save!
  end
  
end