class Event < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :user_id, :user, :type, :place, :can_others_invite, :start, :end, :all_day, :name, :description, :privacy, :location_id, :location, :photo, :any_user
  attr_accessible :user_id, :user, :type, :place, :can_others_invite, :start, :end, :all_day, :name, :description, :privacy, :location_id, :location, :photo
  
  has_many :invites
  accepts_nested_attributes_for :invites

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

  
  

end