class Event < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :user_id, :user, :event_type, :place, :can_others_invite, :start, :end, :all_day, :name, :description, :privacy, :location_id, :location, :photo, :any_user
  attr_accessible :user_id, :user, :event_type, :place, :can_others_invite, :start, :end, :all_day, :name, :description, :privacy, :location_id, :location, :photo, :invites
  
  has_many :invites, :in_json => true
  accepts_nested_attributes_for :invites

  belongs_to :location, :in_json => true
  belongs_to :user, :in_json => true

  PRIVACY = {
    :owner         => "O",
    :invitees      => "I",
    :all_friends   => "F",
    :location      => "L"
  }

  TYPE = {
    :user         => "U",
    :coordinator  => "C"
  }

  validates_presence_of :name, :description, :start, :end

  before_create :set_default_values
  before_create :fix_timestamps
  before_update :fix_timestamps

  def set_default_values
    self.event_type ||= Event::TYPE[:user]
    self.privacy ||= Event::PRIVACY[:owner]
  end

  def fix_timestamps
    if self.start.is_a?(Integer)
      self.start = Time.at(self.start).to_datetime
    end
    if self.end.is_a?(Integer)
      self.end = Time.at(self.end).to_datetime
    end
  end

  def start
    read_attribute(:start).to_i
  end

  def end
    read_attribute(:end).to_i
  end

  def is_user_subscribed?(user)
    user = user.class == User ? user : User.find(user) rescue nil
    return false if user.nil?
    count = user.events_query({:type => "subscribed", :id => self.id, :return => 'count'})
    return count > 0
  end

  # TODO: temporary..
  def as_json(options = nil)
    return AM_as_json(options)
  end

end