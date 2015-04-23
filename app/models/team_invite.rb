class TeamInvite < ApplicationModel

  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :team_id, :user_id, :competition_id, :invite_type, :status, :email, :invited_by, :any_user

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
    :new => 'N',
    :accepted => 'A',
    :declined => 'D'
  }

  TYPE.each_pair do |key, value|
    self.send(:scope, key, where(:type => value))
  end

  TYPE.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.type == value })
  end

  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end

  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  validates_uniqueness_of :user_id, :scope => :team_id, :message => 'already requested/invited.'

  acts_as_notifier

  def set_defaults
    self.invite_type ||= TeamInvite::TYPE[:invited]
    self.status ||= TeamInvite::STATUS[:new]
  end
  
  after_create :send_notifications
  after_update :process
  after_update :send_notifications
  after_destroy :delete_notifications

  # TODO: send emails for notifications and send to unregistered users
  def send_notifications
    if self.user_id.nil? && !self.email.nil?
      # unregistered user, send them an e-mail to join
    else
      # registered user, normal process..
      if self.invite_type == TeamInvite::TYPE[:reguested]
        # user requested to be on team
        if self.status_was != self.status && self.status == TeamInvite::STATUS[:accepted]
          # notify requesting user his request was accepted
          notify(self.user, "You're team request was accepted", "You're request to join \"<a href='/#/team/#{self.team_id}'>#{self.team.name}</a>\" has been accepted.", :from => self.team.leader, :key => "team_invite_#{self.id}")
        elsif self.status == TeamInvite::STATUS[:new]
          # notify team leader that he has a new request
          notify(self.team.leader, "#{self.user.profile.full_name} has requested to join your team.", "#{self.user.profile.full_name} has requested to join \"<a href='/#/team/#{self.team_id}'>#{self.team.name}</a>\".", :from => self.user, :key => "team_invite_#{self.id}")
        end
      elsif self.invite_type == TeamInvite::TYPE[:invited]
        # user was invited by team leader to be on team
        if self.status_was != self.status && self.status == TeamInvite::STATUS[:accepted]
          # notify team leader his invite was accepted
          notify(self.team.leader, "#{self.user.profile.full_name} accepted your team invite.", "#{self.user.profile.full_name} has accepted your invite to join \"<a href='/#/team/#{self.team_id}'>#{self.team.name}</a>\".", :from => self.user, :key => "team_invite_#{self.id}")
        elsif self.status == TeamInvite::STATUS[:new]
          # notify user he's been invited to a team
          notify(self.user, "#{self.inviter.profile.full_name} invited you to join #{self.team.name}.", "#{self.inviter.profile.full_name} invited you to join \"<a href='/#/team/#{self.team_id}'>#{self.team.name}</a>\".", :from => self.inviter, :key => "team_invite_#{self.id}")
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
  end

end