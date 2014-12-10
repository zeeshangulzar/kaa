class ChallengeSent < ApplicationModel
  self.table_name = "challenges_sent"
  attr_privacy_path_to_user :user
  attr_accessible *column_names
  attr_privacy :user, :challenge, :challenged_user, :challenged_group, :me
  
  belongs_to :user
  belongs_to :challenge, :in_json => true
  belongs_to :challenged_user, :class_name => "User", :foreign_key => "to_user_id", :in_json => true
  belongs_to :challenged_group, :class_name => "Group", :foreign_key => "to_group_id", :in_json => true

  validates :user, :presence => true
  validates :challenge, :presence => true
  validates :challenged_user, :presence => true

  validate :unique_challenge_received
  validate :to_user_is_friend

  def unique_challenge_received
    challenge_received = ChallengeReceived.where(:challenge_id => self.challenge_id, :user_id => self.to_user_id).where("expires_on > ? AND status IN (?)", Date.today, [ChallengeReceived::STATUSES[:pending], ChallengeReceived::STATUSES[:accepted]]).first
    if challenge_received
      self.errors.add(:base, "You've already challenged this person.")
      return false
    end
  end

  def to_user_is_friend
    if !self.user || !self.user.friends.include?(self.challenged_user)
      self.errors.add(:base, "You can only challenge your friends.")
      return false
    end
  end

  before_create :create_challenge_received

  def create_challenge_received
    receiver = User.find(self.to_user_id)
    challenge = Challenge.find(self.challenge_id)
    expires_on = receiver.promotion.current_date + 7
    existing = receiver.active_challenges.detect{|c| c.challenge_id == self.challenge_id}
    if existing
      # update the expiration date of the challenge if it's in receiver's queue (he hasn't accepted it yet)
      existing.update_attribute(:expires_on => expires_on) if !existing.accepted?
    else
      # receiver doesn't have this challenge yet
      rcc = receiver.challenges_received.build(:status => ChallengeReceived::STATUSES[:pending], :expires_on => expires_on)
      rcc.challenge = challenge
      if !rcc.valid?
        self.errors.add(:base, rcc.errors.full_messages)
      else
        rcc.save!
      end
    end
  end

end