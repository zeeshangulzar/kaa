class ChallengeSent < ApplicationModel
  self.table_name = "challenges_sent"
  attr_privacy_path_to_user :user
  attr_accessible :user_id, :challenge_id, :created_at, :updated_at, :challenge_sent_users
  attr_privacy :challenge, :challenged_users, :challenged_group, :created_at, :updated_at, :user_id, :me
  
  belongs_to :user
  belongs_to :challenge

  has_many :challenge_sent_users

  has_many :challenged_users, :class_name => "User", :foreign_key => "user_id", :through => :challenge_sent_users
  
  has_many :challenged_group, :class_name => "Group", :foreign_key => "associated_group_id", :through => :challenge_sent_users, :group => "associated_group_id"

  validates :user, :presence => true
  validates :challenge, :presence => true


  accepts_nested_attributes_for :challenge_sent_users

  acts_as_notifier

  def build_users_and_groups(options)
    options[:group_ids] ||= []
    options[:group_ids] = !options[:group_ids].is_a?(Array) ? [options[:group_ids]] : options[:group_ids]
    options[:user_ids] ||= []
    options[:user_ids] = !options[:user_ids].is_a?(Array) ? [options[:user_ids]] : options[:user_ids]

    # keep track of everyone challenge has been sent to
    sent_to_users = self.challenged_users.collect{|cu|cu.id}
    
    options[:group_ids].each{|group_id|
      g = self.user.groups.find(group_id) rescue nil
      if g
        # only send to users in groups owned by user
        g.users.each{|group_user|
          unless !self.user.friends.include?(group_user) || sent_to_users.include?(group_user.id)
            challenge_received = group_user.active_challenges.where(:challenge_id => self.challenge_id).first
            unless challenge_received && challenge_received.challengers.collect{|x|x.id}.include?(self.user_id)
              Rails.logger.warn("User hasnt received this challenge, wtf")
              # only send to friends
              # shouldn't need this check but it MAY BE possible groups could be corrupted and contain users you're no longer friends with
              self.challenge_sent_users.create(:user_id => group_user.id, :associated_group_id => g.id)
              sent_to_users.push(group_user.id.to_i)
            end
          end
        }
      end
    }
    options[:user_ids].each{|user_id|
      next if sent_to_users.include?(user_id.to_i) # already sent to this user
      u = self.user.friends.find(user_id) rescue nil
      if u
        challenge_received = u.active_challenges.where(:challenge_id => self.challenge_id).first
        unless challenge_received && challenge_received.challengers.collect{|x|x.id}.include?(self.user_id)
          self.challenge_sent_users.create(:user_id => u.id)
          sent_to_users.push(u.id.to_i)
        end
      end
    }
    return self.challenged_users.reload
  end


  # return any users or groups which are invalid and/or already have received the sent challenge from challenge_sent.user
  def check_users_and_groups(options)
    options[:group_ids] ||= []
    options[:group_ids] = !options[:group_ids].is_a?(Array) ? [options[:group_ids]] : options[:group_ids]
    options[:user_ids] ||= []
    options[:user_ids] = !options[:user_ids].is_a?(Array) ? [options[:user_ids]] : options[:user_ids]

    # keep track of everyone already checked
    already_checked_users = []
    invalid_users = []
    invalid_groups = []

    options[:group_ids].each{|group_id|
      g = self.user.groups.find(group_id) rescue nil
      if g
        g.users.each{|group_user|
          next if already_checked_users.include?(group_user.id) # no need to keep checking
          if !self.user.friends.include?(group_user)
            # can't send to not friends, this shouldn't be possible if they're in the user's group but data corruption MAY BE possible
            invalid_users.push(group_user.id)
          else
            # users are friends, check to see if receiver already has this challenge from sender
            challenge_received = group_user.active_challenges.where(:challenge_id => self.challenge_id).first
            if challenge_received && challenge_received.challengers.collect{|x|x.id}.include?(self.user_id)
              # got it already
              invalid_users.push(group_user.id)
            end
          end
          already_checked_users.push(group_user.id)
        }
        if (g.users.collect{|u|u.id}-invalid_users).empty?
          # all users in this group are invalid, so mark the group invalid
          invalid_groups.push(group_id)
        end
      else
        # group either doesn't exist or isn't owned by challenge_sent.user
        invalid_groups.push(group_id)
      end
    }
    options[:user_ids].each{|user_id|
      next if already_checked_users.include?(user_id.to_i) # already checked this user
      u = self.user.friends.find(user_id) rescue nil
      if u
        # users are friends, check to see if receiver already has this challenge from sender
        challenge_received = u.active_challenges.where(:challenge_id => self.challenge_id).first
        if challenge_received && challenge_received.challengers.collect{|x|x.id}.include?(self.user_id)
          invalid_users.push(u.id)
        end
      else
        # user either doesn't exist or isn't friends with challenge_sent.user
        invalid_users.push(user_id)
      end
    }
    return {:users => invalid_users, :groups => invalid_groups}
  end


  # after create no longer works thanks to challenge_sent_users many-to-many
  #after_create :create_challenges_received

  def create_challenges_received
    challenge = Challenge.find(self.challenge_id)
    self.challenged_users.each do |receiver|
      existing = receiver.active_challenges.detect{|c| c.challenge_id == self.challenge_id}
      if !existing
        rcc = receiver.challenges_received.build(:status => ChallengeReceived::STATUS[:unseen])
        rcc.challenge = challenge
        if !rcc.valid?
          self.errors.add(:base, rcc.errors.full_messages)
        else
          rcc.save!
          notify(receiver, "Challenge Received", "#{self.user.profile.full_name} challenged you to <a href='/#/challenges'>#{self.challenge.name}</a>.", :from => self.user, :key => "challenge_sent_#{id}")
          if receiver.flags[:notify_email_challenges]
            Resque.enqueue(ChallengeReceivedEmail, self.id, receiver.id)
          end
        end
      else
        notify(receiver, "Challenge Received", "#{self.user.profile.full_name} has also challenged you to <a href='/#/challenges'>#{self.challenge.name}</a>.", :from => self.user, :key => "challenge_sent_#{id}")
        if receiver.flags[:notify_email_challenges]
          Resque.enqueue(ChallengeReceivedEmail, self.id, receiver.id)
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

  after_create :do_badges

  def do_badges
    Badge.do_coach(self)
  end

end
