class Map < ApplicationModel
  attr_privacy :id, :name, :status, :settings, :public
  attr_privacy_no_path_to_user
  attr_accessible *column_names

  many_to_many :with => :promotion, :primary => :promotion, :order => "id ASC", :allow_duplicates => false

  # TODO: do these make sense?
  STATUS = {
    :inactive => 0,
    :active   => 1,
    :deleted  => 2
  }
  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end
  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  def settings
    return {
      :image_dir       => self.image_dir,
      :tile_size       => self.tile_size,
      :min_zoom        => self.min_zoom,
      :max_zoom        => self.max_zoom,
      :adjusted_width  => self.adjusted_width,
      :adjusted_height => self.adjusted_height,
      :scale_zoom      => self.scale_zoom,
      :scaled_min_zoom => self.scaled_min_zoom,
      :image_width     => self.image_width,
      :image_height    => self.image_height
    }
  end

  def image_dir
    # TODO: make this do things
    return "/images/default/map/map_detailed"
  end

  def destroy
    # TODO: we want to do a soft delete, so figure out what this should do...
    self.deleted = true
    self.save!
  end
  
end