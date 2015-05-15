class TeamInvite < ApplicationModel

  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :team_id, :user_id, :competition_id, :invite_type, :status, :email, :invited_by, :user, :team, :message, :any_user

  belongs_to :user
  belongs_to :inviter, :class_name => "User", :foreign_key => "invited_by"
  belongs_to :team
  belongs_to :competition

  TYPE = {
    :requested => 'R',
    :invited => 'I'
  }

  STATUS = {
    :unresponded => 'U',
    :accepted => 'A',
    :declined => 'D'
  }
  
  # validate
  validate :not_already_on_team
  validates_uniqueness_of :user_id, :scope => :team_id, :message => 'already requested/invited.', :allow_nil => true

  acts_as_notifier

  before_create :set_defaults
  after_create :create_notifications
  after_update :create_notifications
  after_destroy :destroy_notifications

  TYPE.each_pair do |key, value|
    self.send(:scope, key, where(:invite_type => value))
  end

  TYPE.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.invite_type == value })
  end

  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end

  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  def set_defaults
    self.invite_type ||= TeamInvite::TYPE[:invited]
    self.status ||= TeamInvite::STATUS[:unresponded]
  end

  def not_already_on_team
    if self.user.current_team
      self.errors[:base] << "User is already on a team."
    end
  end

  # TODO: send emails for notifications
  def create_notifications
    if self.user_id.nil? && !self.email.nil?
      # unregistered user, send them an e-mail to join
      Resque.enqueue(UnregisteredTeamInviteEmail, self.email, self.inviter.id, self.message)
    else
      # registered user, normal process..
      if self.invite_type == TeamInvite::TYPE[:requested]
        # user requested to be on team
        if self.status_was != self.status && self.status == TeamInvite::STATUS[:accepted]
          $redis.publish("TeamInviteAccepted", {:team => self.team, :user_id => self.user_id}.to_json)
          # notify requesting user his request was accepted
          self.user.notify(self.user, "Your team request was accepted", "Your request to join \"<a href='/#/team?team_id=#{self.team_id}'>#{self.team.name}</a>\" has been accepted.", :from => self.team.leader, :key => "team_#{self.team_id}_invite_#{self.id}_request_accepted")
          # create team member
          self.add_team_member
        elsif self.status == TeamInvite::STATUS[:unresponded]
          # notify team leader that he has a new request
          notify(self.team.leader, "#{self.user.profile.full_name} has requested to join your team.", "#{self.user.profile.full_name} has <a href='/#/team?tab=invites'>requested</a> to join \"#{self.team.name}\".", :from => self.user, :key => "team_#{self.team_id}_invite_#{self.id}_request_made")
          Resque.enqueue(TeamInviteEmail, 'requested', self.team.leader.id, self.user.id, self.message)
        end
      elsif self.invite_type == TeamInvite::TYPE[:invited]
        # user was invited by team leader to be on team
        if self.status_was != self.status && self.status == TeamInvite::STATUS[:accepted]
          $redis.publish("TeamInviteAccepted", {:team => self.team, :user_id => self.user_id}.to_json)
          # notify team leader his invite was accepted
          self.team.leader.notify(self.team.leader, "#{self.user.profile.full_name} accepted your team invite.", "#{self.user.profile.full_name} has accepted your invite to join \"<a href='/#/team?team_id=#{self.team_id}'>#{self.team.name}</a>\".", :from => self.user, :key => "team_#{self.team_id}_invite_#{self.id}_invite_accepted")
          # create team member
          self.add_team_member
        elsif self.status == TeamInvite::STATUS[:unresponded]
          # notify user he's been invited to a team
          notify(self.user, "#{self.inviter.profile.full_name} invited you to join #{self.team.name}.", "#{self.inviter.profile.full_name} invited you to join \"<a href='/#/team?team_id=#{self.team_id}'>#{self.team.name}</a>\".", :from => self.inviter, :key => "team_#{self.team_id}_invite_#{self.id}_invite_made")
          Resque.enqueue(TeamInviteEmail, 'invited', self.user.id, self.inviter.id, self.message)
        end
      end
    end
  end

  def destroy_notifications
    unless self.user_id.nil?
      Notification.find(:all, :conditions => ["`key` like ?", "team_#{self.team_id}_invite_#{self.id}_request_made"]).each{|x| x.destroy}
      Notification.find(:all, :conditions => ["`key` like ?", "team_#{self.team_id}_invite_#{self.id}_invite_made"]).each{|x| x.destroy}
    end
  end

  def add_team_member
    if self.status_was != self.status && self.status == TeamInvite::STATUS[:accepted]
      TeamInvite.transaction do
        self.team.team_members.create(:user_id => self.user_id, :competition_id => self.team.competition_id, :is_leader => 0)
      end
    end
  end

end
