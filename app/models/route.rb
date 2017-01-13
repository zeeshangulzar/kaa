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
    :deleted  => 'deleted',
    :locked   => 'locked'
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

  # we need the order of the route's destinations, quickly.
  # this will be used A LOT when constructing users' destinations w/entries, etc.
  def self.ordered_destination_ids(route_or_id)
    route = route_or_id.is_a?(Integer) ? Route.find(route_or_id) : route_or_id
    cache_key = "#{route.cache_key}-destination_ids"
    puts cache_key
    order = Rails.cache.fetch(cache_key) do
      a = []
      h = JSON.parse(route.ordered_destinations) rescue nil
      if h.nil?
        nil
      else
        h.each{|d|
          a << d['id']
        }
        a
      end
    end
    return order
  end
  
end