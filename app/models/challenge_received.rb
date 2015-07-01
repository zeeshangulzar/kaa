class ChallengeReceived < ApplicationModel
  self.table_name = "challenges_received"

  attr_privacy_path_to_user :user
  attr_accessible :challenge_id, :user_id, :status, :expires_on, :completed_on, :created_at, :updated_at, :challenge, :notes, :user
  attr_privacy :challenge_id, :user_id, :status, :expires_on, :completed_on, :created_at, :updated_at, :notes, :me
  
  belongs_to :user
  belongs_to :challenge, :in_json => true

  validates_presence_of :challenge_id, :status

  STATUS = {
    :unseen    => 0,
    :pending   => 1,
    :accepted  => 2,
    :completed => 3,
    :declined  => 4
  }

  acts_as_notifier
  after_update :send_notification
  before_create :set_defaults
  before_create :set_expiration_if_accepted
  before_update :set_expiration_if_accepted
  before_update :set_completed_on_if_completed
  after_commit :entry_calculate_points

  def set_defaults
    self.status ||= STATUS[:unseen]
  end

  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end

  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  def expired?
    return !self.expires_on.nil? && self.expires_on < self.challenge.promotion.current_date
  end

  def challengers
    # self.created_at - 5, because of the potential for delay between ChallengeSent, which triggers ChallengeReceived to be created
    if self.challenge.type == Challenge::TYPE[:regional]
      user_ids = [self.challenge.created_by]
    else
      user_ids = ChallengeSent.joins(:challenge_sent_users).where("challenges_sent.challenge_id = ? AND challenge_sent_users.created_at >= ? AND challenge_sent_users.created_at <= ? AND challenge_sent_users.user_id = ?", self.challenge.id, self.created_at - 30, (self.completed_on ? self.completed_on : self.user.promotion.current_time), self.user.id).order("challenges_sent.created_at ASC").collect{|cs|cs.user_id}
      user_ids = [user_ids] if !user_ids.is_a?(Array)
    end
    return user_ids.empty? ? [] : User.where("id IN (#{user_ids.join(',')})")
  end

  def as_json(options={})
    cr_json = super(options)
    cr_json["challengers"] = self.challengers
    cr_json
  end

  def set_expiration_if_accepted
    if self.expires_on.nil? && self.accepted?
      self.expires_on = self.user.promotion.current_time + (86400 * 7)
    end
  end

  def set_completed_on_if_completed
    if self.completed? && self.status_was != STATUS[:completed]
      self.completed_on = self.challenge.promotion.current_time
    end
  end

  def entry_calculate_points
    e = self.user.entries.find_by_recorded_on(self.user.promotion.current_date)
    if !e
      e = self.user.entries.create(:recorded_on => self.user.promotion.current_date)
    end
    e.save! # fires Entry::calculate_points
  end

  def send_notification
    if self.accepted? && self.status_was != STATUS[:accepted]
      # accepted notification
      self.challengers.each{|challenger|
        notify(challenger, "Challenge Accepted", "#{self.user.profile.full_name} accepted your challenge to <a href='/#/challenges'>#{self.challenge.name}</a>.", :from => self.user, :key => "challenge_received_#{id}")
      }
    end
    if self.completed? && self.status_was != STATUS[:completed]
      # completed notification
      self.challengers.each{|challenger|
        self.notify(challenger, "Challenge Completed", "#{self.user.profile.full_name} completed your challenge to <a href='/#/challenges'>#{self.challenge.name}</a>.", :from => self.user, :key => "challenge_received_#{id}")
      }
    end
  end

  after_update :do_badges

  def do_badges
    Badge.do_rookie(self)
    Badge.do_mvp(self)
  end

end
