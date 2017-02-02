class Map < ApplicationModel

  serialize :settings, JSON

  CACHE_KEY_INCLUDES = [:routes, :destinations]

  attr_privacy :id, :name, :summary, :status, :settings, :image_dir, :public
  attr_privacy :routes, :master
  attr_privacy_no_path_to_user
  attr_accessible :name, :summary, :created_at, :updated_at, :settings, :image_dir

  many_to_many :with => :promotion, :primary => :promotion, :order => "id ASC", :allow_duplicates => false

  has_many :routes
  has_many :destinations, :order => "sequence ASC"

  validate :validate_settings

  before_create :set_defaults

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

  def set_defaults
    # TODO: make this do things
    self.image_dir = "/images/default/map/map_detailed" if self.image_dir.nil?
  end

  def validate_settings
    required = ['tile_size', 'min_zoom', 'max_zoom', 'scale_zoom']
    if !required.all?{|k| !self.settings[k].nil? }
      self.errors[:base] << "#{required.join(', ')} required."
    end
  end

  def destroy
    # TODO: we want to do a soft delete, so figure out what this should do...
    self.status = STATUS[:deleted]
    self.save!
  end

end
