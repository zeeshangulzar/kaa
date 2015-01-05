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

  # very similar to User::subscribed_events, just switching some ids and adding a condition
  # TODO: possibly consolidate the two?
  def is_user_subscribed?(user)
    user = user.class == User ? user : User.find(user) rescue nil
    return false if user.nil?
    sql = "
SELECT
COUNT(events.id) AS count
FROM events
LEFT JOIN invites my_invite ON my_invite.event_id = events.id AND (my_invite.invited_user_id = #{user.id})
JOIN users on events.user_id = users.id
JOIN profiles on profiles.user_id = users.id
WHERE
(
  # my events
  (
    events.user_id = #{user.id}
  )
  OR
  # my friends events with privacy = all_friends
  (
    (
      events.user_id in (select friendee_id from friendships where (friender_id = #{user.id}) AND friendships.status = 'A')
      OR
      events.user_id in (select friender_id from friendships where (friendee_id = #{user.id}) AND friendships.status = 'A')
    )
    AND events.user_id <> #{user.id}
    AND events.privacy = 'F'
  )
  OR
  # events i'm invited to
  (
    my_invite.invited_user_id = #{user.id}
  )
  OR
  # coordinator events in my area
  (
    events.event_type = 'C'
    AND events.privacy = 'L'
    AND (events.location_id IS NULL OR events.location_id = #{user.location_id})
  )
)
AND
(
  events.id = #{self.id}
)
    "
    count = Event.count_by_sql(sql)
    return count > 0
  end


end