# Location active record class for keeping track of locations assigned to another model
class Location < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :name, :sequence, :root_location_id, :parent_location_id, :public
  attr_accessible  :promotion_id, :name, :sequence, :root_location_id, :parent_location_id


  # The parent location that the location belongs to, will be nil for root location
  belongs_to :parent_location, :class_name => 'Location'

  # The very top level location that the location belongs to, will be nil for root location
  belongs_to :root_location, :class_name => 'Location'

  # Returns all locations that are one level under a parent location
  has_many :locations, :class_name => 'Location', :foreign_key => 'parent_location_id', :order => 'sequence', :dependent => :destroy

  # Return all locations that are under a root location
  has_many :all_locations, :class_name => 'Location', :foreign_key => 'root_location_id', :order => 'sequence', :dependent => :destroy

  # Returns only top locations
  #
  # @example
  #  @promotion.locations.top
  scope :top, where(:parent_location_id => nil).includes(:locations)

  # Returns locations on the level specified
  #
  # @example
  #  @promotion.locations.level(1)
  scope :level, lambda { |depth_level| where(:depth => depth_level)}

  # Cannot save a location with the same name assigned to the same parent or at the top level
  validates_uniqueness_of :name, :scope => [:parent_location_id]

  # Set the root location and depth before saving
  before_save :set_root_location_and_depth

  # Update the depth on the locationable object
  # TODO: make this work maybe..
  # after_save :update_depth_on_locationable

  # Set locationable type and id before saving
  # TODO: make this work maybe..
  # before_save :set_locationable_for_nested

  # Don't destroy is instances are assigned to location
  before_destroy :make_sure_is_empty

  # Sets the root location for nested locations and their correct depth level
  #
  # @return [Boolean] true if set successfully, false otherwise
  def set_root_location_and_depth
    if parent_location
      self.root_location = parent_location
      self.depth = 2

      while self.root_location.root_location
        self.root_location = self.root_location.root_location
        self.depth += 1
      end
    else
      self.depth = 1
    end

    true
  end


  # Sets the bottom depth level on the locationable model
  #
  # @return [Boolean] true if set successfully, false otherwise
  def update_depth_on_locationable
    return true if locationable.nil?

    locationable.locations.reload
    new_depth = locationable.location_levels

    locationable.set_location_label('Nested Location', new_depth) if new_depth > locationable.location_labels.size
    locationable.locations_depth = new_depth
    locationable.save
  end

  # Sets the locationable model for all nested locations
  #
  # @return [Boolean] true if set successfully, false otherwise
  def set_locationable_for_nested
    return true if parent_location.nil? || parent_location.locationable.nil?

    self.locationable = parent_location.locationable

    true
  end

  # Makes sure a location has no instances assigned to it before destroying
  #
  # @return [Boolean] true if empty, false if not empty
  def make_sure_is_empty
    return empty?
  end

  # Returns whether or not this is a root location
  #
  # @return [Boolean] true if top (root) location, false if nested location
  def is_top?
    parent_location_id.nil?
  end

  # Returns whether or not their are instances assigned to this location
  #
  # @return [Boolean] true if location is empty, false if location is not empty
  def empty?
    self.class.assigned_models.each do |assigned_model|
      _location = self
      return false unless _location.send(assigned_model.table_name).empty?

      until _location.is_top?
        _location = _location.parent_location
        return true if _location.nil?
        return false unless _location.send(assigned_model.table_name).empty?
      end
    end

    true
  end

  # Overrides the as_json method so that nested locations are included be default
  def as_json(options = {})
    super(options.merge({:include => [:locations]}))
  end
end
