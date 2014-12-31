class Event < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :user_id, :user, :event_type, :place, :can_others_invite, :start, :end, :all_day, :name, :description, :privacy, :location_id, :location, :photo, :any_user
  attr_accessible :user_id, :user, :event_type, :place, :can_others_invite, :start, :end, :all_day, :name, :description, :privacy, :location_id, :location, :photo
  
  has_many :invites
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

  def set_default_values
    self.event_type ||= Event::TYPE[:user]
    self.privacy ||= Event::PRIVACY[:owner]
  end
  

end