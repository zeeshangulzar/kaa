class Event < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :id, :user_id, :user, :event_type, :place, :can_others_invite, :start, :end, :all_day, :name, :description, :privacy, :location_id, :location, :photo, :is_canceled, :any_user
  attr_accessible :user_id, :user, :event_type, :place, :can_others_invite, :start, :end, :all_day, :name, :description, :privacy, :location_id, :location, :photo, :invites, :is_canceled
  
  has_many :invites
  accepts_nested_attributes_for :invites

  belongs_to :location, :in_json => true
  belongs_to :user, :in_json => true

  mount_uploader :photo, EventPhotoUploader

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

  acts_as_notifier

  after_create :invited_notifications
  after_update :updated_notifications

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

  def canceled?
    return self.is_canceled == true
  end

  def is_user_subscribed?(user)
    user = user.class == User ? user : User.find(user) rescue nil
    return false if user.nil?
    count = user.events_query({:type => "subscribed", :id => self.id, :return => 'count', :include_canceled => true})
    return count > 0
  end

  def as_json(options = {})
    options = options.merge({:methods => ["attendance"]})
    super
  end

  def attendance
    hash = Invite::STATUS.clone
    hash.each{|k,v| hash[k] = 0}
    sql = "SELECT invites.status, COUNT(DISTINCT(invites.invited_user_id)) AS users FROM invites WHERE invites.event_id = #{self.id} GROUP BY invites.status"
    res = ActiveRecord::Base.connection.select_rows(sql)
    res.each{|row|hash[Invite::STATUS.index(row[0].to_i)] = row[1]}

    if self.event_type == Event::TYPE[:coordinator] && self.privacy == Event::PRIVACY[:location]
      # get all users in location and children locations
      total_users = !self.location.nil? ? self.location.users.count : self.user.promotion.users.count
      total_users += -1 # minus 1 for the coordinator
    elsif self.event_type == Event::TYPE[:user] && self.privacy == Event::PRIVACY[:all_friends]
      # get all user's friends
      total_users = self.user.friends.count
    else
      total_users = hash.values.sum
    end

    additional_unresponded = total_users - hash.values.sum
    hash[:unresponded] += additional_unresponded

    return JSON.parse(hash.to_json)
  end



  # TODO: add emails
  def invited_notifications
    return if self.event_type != Event::TYPE[:user]
    recipients = []
    if self.privacy == Event::PRIVACY[:invitees]
      recipients = self.invites
    elsif self.privacy == Event::PRIVACY[:all_friends]
      recipients = self.user.friends
    end
    recipients.each{|recipient|
      notify(recipient, "You're invite to an event", "You've been invited to #{self.user.profile.full_name}'s event, \"<a href='/#/event/#{self.id}'>#{self.name}</a>\".", :from => self.user, :key => "event_#{self.id}")
    }
  end


  # TODO: add emails
  # TODO: make this run in the background.. resque or something?
  def updated_notifications
    return if self.event_type != Event::TYPE[:user]
    n = false
    if !self.is_canceled && self.start_was != self.start || self.end_was != self.end || self.place_was != self.place
      n = {
        :title   => "Event Updated",
        :message => "#{self.user.profile.full_name}'s event, \"<a href='/#/event/#{self.id}'>#{self.name}</a>\", has been updated."
      }
    end
    if self.is_canceled && self.is_canceled_was != self.is_canceled
      n = {
        :title   => "Event Canceled",
        :message => "#{self.user.profile.full_name}'s event, \"<a href='/#/event/#{self.id}'>#{self.name}</a>\", has been canceled."
      }
    end
    return unless n
    self.invites.attending.each{|invite|
      recipient = invite.user
      notify(recipient, n[:title], n[:message], :from => self.user, :key => "event_#{self.id}")
    }
  end

end