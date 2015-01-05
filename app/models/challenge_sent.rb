class ChallengeSent < ApplicationModel
  self.table_name = "challenges_sent"
  attr_privacy_path_to_user :user
  attr_accessible :user_id, :challenge_id, :to_user_id, :to_group_id, :created_at, :updated_at
  attr_privacy :user, :challenge, :challenged_user, :challenged_group, :created_at, :updated_at, :me
  
  belongs_to :user
  belongs_to :challenge, :in_json => true
  belongs_to :challenged_user, :class_name => "User", :foreign_key => "to_user_id", :in_json => true
  belongs_to :challenged_group, :class_name => "Group", :foreign_key => "to_group_id", :in_json => true

  validates :user, :presence => true
  validates :challenge, :presence => true

  validate :unique_challenge_received
  validate :to_user_or_group

  def unique_challenge_received    
    user = User.find(self.user_id)
    if !self.to_user_id.nil?
      challenge_received = ChallengeReceived.where(:challenge_id => self.challenge_id, :user_id => self.to_user_id).where("(expires_on IS NULL OR expires_on >= ?) AND status IN (?)", Time.now.utc.to_s(:db), [ChallengeReceived::STATUS[:unseen], ChallengeReceived::STATUS[:pending], ChallengeReceived::STATUS[:accepted]]).first
      if challenge_received && challenge_received.challengers.collect{|x|x.id}.include?(self.user_id)
        # below is an incomplete but different way of getting sent challenge
        # cs = ChallengeSent.where(:challenge_id => self.challenge_id, :user_id => self.user_id).where("(to_user_id = #{self.to_user_id} OR to_group_id IN (#{user.groups_with_user(self.to_user_id).collect{|x|x.id}.join(',')})").where("created_at >= '?'", Time.now.utc.to_s(:db), challenge_received.created_at).first
        self.errors.add(:base, "You've already challenged this person to this.")
        return false
      end
    else
      return true
    end
  end


  def to_user_or_group
    if !self.to_user_id.nil?
      if !self.user || !self.user.friends.include?(self.challenged_user)
        self.errors.add(:base, "You can only challenge your friends.")
        return false
      end
    elsif !self.to_group_id.nil?
      if !self.challenged_group || self.challenged_group.owner.id != self.user.id
        self.errors.add(:base, "You can't access this group.")
        return false
      end
    else
      self.errors.add(:base, "Must provide user or group.")
      return false
    end
  end

  before_create :create_challenge_received

  def create_challenge_received
    challenge = Challenge.find(self.challenge_id)
    receivers = self.to_group_id.nil? ? [self.challenged_user] : self.challenged_group.users
    receivers.each do |receiver|
      existing = receiver.active_challenges.detect{|c| c.challenge_id == self.challenge_id}
      if !existing
        rcc = receiver.challenges_received.build(:status => ChallengeReceived::STATUS[:unseen])
        rcc.challenge = challenge
        if !rcc.valid?
          self.errors.add(:base, rcc.errors.full_messages)
        else
          rcc.save!
        end
      end
    end
    
#    #expires_on = receiver.promotion.current_date + 7
#    existing = receiver.active_challenges.detect{|c| c.challenge_id == self.challenge_id}
#    if existing
#      # update the expiration date of the challenge if it's in receiver's queue (he hasn't accepted it yet)
#      #existing.update_attribute(:expires_on => expires_on) if !existing.accepted?
#      # NOTE: not expiring new challenges now, they only expire once they've been accepted
#    else
#      # receiver doesn't have this challenge yet
#      #rcc = receiver.challenges_received.build(:status => ChallengeReceived::STATUS[:pending], :expires_on => expires_on)
#      # NOTE: not expiring new challenges now, they only expire once they've been accepted
#      rcc = receiver.challenges_received.build(:status => ChallengeReceived::STATUS[:unseen])
#      rcc.challenge = challenge
#      if !rcc.valid?
#        self.errors.add(:base, rcc.errors.full_messages)
#      else
#        rcc.save!
#      end
#    end
  end

  after_create :entry_calculate_points
  after_update :entry_calculate_points

  def entry_calculate_points
    e = self.user.entries.find_by_recorded_on(self.user.promotion.current_date)
    if !e
      e = self.user.entries.create(:recorded_on => self.user.promotion.current_date)
    end
    e.save! # fires Entry::calculate_points
  end

end