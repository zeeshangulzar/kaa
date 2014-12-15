class ChallengeReceived < ApplicationModel
  self.table_name = "challenges_received"

  attr_privacy_path_to_user :user
  attr_accessible :challenge_id, :user_id, :status, :expires_on, :completed_on, :created_at, :updated_at, :challenge, :notes, :user
  attr_privacy :challenge_id, :user_id, :status, :expires_on, :completed_on, :created_at, :updated_at, :notes, :me
  
  belongs_to :user
  belongs_to :challenge, :in_json => true

  # has_many :challenges_sent, :class_name => "ChallengeSent", :foreign_key => nil, :source => :user, :conditions => proc { "challenges_sent.to_user_id = challenges_received.user_id AND challenges_sent.challenge_id = challenges_received.challenge_id AND challenges_sent.created_at >= challenges_received.created_at" }
  # has_many :challengers, :class_name => "User", :through => :challenges_sent, :source => :user

  STATUS = {
    :unseen    => 0,
    :pending   => 1,
    :accepted  => 2,
    :completed => 3,
    :declined  => 4
  }

  before_create :set_defaults
  before_update :set_expiration_if_accepted

  def set_defaults
    self.status ||= STATUS[:unseen]
  end

  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end

  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  def challengers
    # self.created_at - 5, because of the potential for delay between ChallengeSent, which triggers ChallengeReceived to be created
    user_ids = ChallengeSent.where("to_user_id = ? AND challenge_id = ? AND challenges_sent.created_at >= ?", self.user_id, self.challenge.id, self.created_at - 5).collect{|cs|cs.user_id}
    return User.where("id IN (?)", user_ids)
  end

  def as_json(options={})
    cr_json = super(options)
    cr_json["challengers"] = self.challengers
    cr_json
  end

  def set_expiration_if_accepted
    if self.read_attribute(:expires_on).nil? && self.accepted?
      self.expires_on = self.user.promotion.current_date + 7
    end
  end

end