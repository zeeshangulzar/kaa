class Route < ApplicationModel
  attr_privacy :id, :name, :travel_type, :status, :length, :points, :ordered_destinations, :overlay_image, :public
  attr_privacy_no_path_to_user
  attr_accessible :map_id, :name, :travel_type, :status, :length, :points, :ordered_destinations, :overlay_image, :created_at, :updated_at

  belongs_to :map

  mount_uploader :overlay_image, RouteOverlayImageUploader

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

  def destroy
    # TODO: we want to do a soft delete, so figure out what this should do...
    self.status = STATUS[:deleted]
    self.save!
  end

  def as_json(options = {})
    json = super(options)
    json['ordered_destinations'] = JSON.parse(self.ordered_destinations) rescue nil # TODO: make this faster and more efficient
    json['points'] = JSON.parse(self.points) rescue nil # TODO: make this faster and more efficient 
    return json
  end
  
end