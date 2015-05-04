class TeamInvite < ApplicationModel

  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :team_id, :user_id, :competition_id, :invite_type, :status, :email, :invited_by, :user, :team, :any_user

  before_create :set_defaults

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

  validates_uniqueness_of :user_id, :scope => :team_id, :message => 'already requested/invited.', :allow_nil => true

  acts_as_notifier

  def set_defaults
    self.invite_type ||= TeamInvite::TYPE[:invited]
    self.status ||= TeamInvite::STATUS[:unresponded]
  end
  
  after_create :send_notifications
  after_update :send_notifications
  after_destroy :delete_notifications

  # TODO: send emails for notifications
  def send_notifications
    if self.user_id.nil? && !self.email.nil?
      # unregistered user, send them an e-mail to join
      Resque.enqueue(UnregisteredTeamInviteEmail, self.email, self.inviter.id)
    else
      # registered user, normal process..
      if self.invite_type == TeamInvite::TYPE[:requested]
        # user requested to be on team
        if self.status_was != self.status && self.status == TeamInvite::STATUS[:accepted]
          # notify requesting user his request was accepted
          notify(self.user, "You're team request was accepted", "You're request to join \"<a href='/#/team?team_id=#{self.team_id}'>#{self.team.name}</a>\" has been accepted.", :from => self.team.leader, :key => "team_invite_#{self.id}")
          self.add_team_member
        elsif self.status == TeamInvite::STATUS[:unresponded]
          # notify team leader that he has a new request
          notify(self.team.leader, "#{self.user.profile.full_name} has requested to join your team.", "#{self.user.profile.full_name} has <a href='/#/team?tab=invites'>requested</a> to join \"#{self.team.name}\".", :from => self.user, :key => "team_invite_#{self.id}")
          Resque.enqueue(TeamInviteEmail, 'requested', self.team.leader.id, self.user.id)
        end
      elsif self.invite_type == TeamInvite::TYPE[:invited]
        # user was invited by team leader to be on team
        if self.status_was != self.status && self.status == TeamInvite::STATUS[:accepted]
          # notify team leader his invite was accepted
          notify(self.team.leader, "#{self.user.profile.full_name} accepted your team invite.", "#{self.user.profile.full_name} has accepted your invite to join \"<a href='/#/team?team_id=#{self.team_id}'>#{self.team.name}</a>\".", :from => self.user, :key => "team_invite_#{self.id}")
          self.add_team_member
        elsif self.status == TeamInvite::STATUS[:unresponded]
          # notify user he's been invited to a team
          notify(self.user, "#{self.inviter.profile.full_name} invited you to join #{self.team.name}.", "#{self.inviter.profile.full_name} invited you to join \"<a href='/#/team?team_id=#{self.team_id}'>#{self.team.name}</a>\".", :from => self.inviter, :key => "team_invite_#{self.id}")
          Resque.enqueue(TeamInviteEmail, 'invited', self.user.id, self.inviter.id)
        end
      end
    end
  end

  def delete_notifications
    if self.user_id.nil? && !self.email.nil?
      # unregistered user, do nothing...
    else
      # TODO: figure out how to delete these notifications...
    end
  end

  def add_team_member
    if self.status_was != self.status && self.status == TeamInvite::STATUS[:accepted]
      TeamInvite.transaction do
        self.team.team_members.create(:user_id => self.user_id, :competition_id => self.team.competition_id, :is_leader => 0)
      end
    end
    self.user.team_invites.each{ |invite|
      TeamInvite.transaction do
        invite.destroy
      end
    }
  end

end