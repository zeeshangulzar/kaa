class Team < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :name, :motto, :image, :leader, :total_points, :avg_points, :member_count, :status, :any_user

  has_many :team_members
  has_many :members, :through => :team_members, :source => :user
  has_many :team_invites
  has_one :leader, :through => :team_members, :source => :user, :conditions => "is_leader = 1"

  validates_presence_of :name

  validates_uniqueness_of :name, :case_sensitive => false, :scope => :competition_id

  mount_uploader :image, TeamImageUploader

  has_photos
  has_wall
  belongs_to :competition

  acts_as_notifier

  STATUS = {
    :pending => 0,
    :official => 1,
    :deleted => 2
  }

  after_save :handle_status
  before_destroy :disband
  before_destroy :delete_team_members

  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end

  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  def as_json(options={})
    team_json = super(options.merge(:do_not_paginate=>['team_members']))
    return team_json
  end

  def leader
    unless self.team_members.where(:is_leader => 1).empty?
      return self.team_members.where(:is_leader => 1).first.user
    end
    return nil
  end

  def disband
    return true unless self.status_was != Team::STATUS[:deleted]
    # delete all team notifications (we only want to retain disbanded notifications, which are generated after this..
    Notification.find(:all, :conditions => ["`key` like ?", "team_#{self.id}%"]).each{|x| x.destroy}
    self.team_invites.each{ |invite|
      if invite.user
        invite.user.notify(invite.user, "The team \"#{self.name}\" has been disbanded.", "The team \"#{self.name}\" has been disbanded.", :from => self.leader, :key => "team_#{self.id}_deleted")
      end
      invite.destroy
    }
    self.members.each do |member|
      # create disbanded notification
      message = "#{self.name} has been disbanded."
      message = message + " You can <a href=\"/#/team\">join or start</a> a different team." unless self.competition.enrollment_ends_on < self.competition.promotion.current_date
      member.notify(member, message, message, :from => self.leader, :key => "team_#{self.id}_deleted")
    end
  end

  def delete_team_members
    self.team_members.each{|team_member| team_member.destroy}
  end

  def stats
    return @stats if !@stats.nil?
    @stats = {}
    sql = "
      SELECT
        SUM(members.total_points) AS total_points,
        SUM(members.total_points)/COUNT(DISTINCT(members.user_id)) AS avg_points,
        COUNT(DISTINCT(members.user_id)) AS member_count
      FROM teams
        JOIN competitions ON competitions.id = teams.competition_id
        JOIN team_members AS members ON members.team_id = teams.id
      WHERE
        teams.id = #{self.id}
    "
    result = self.connection.exec_query(sql)
    result.first.each{|k,v|
      @stats[k.to_sym] = v
    }
    return @stats
  end

  def member_count
    @stats = self.stats if !@stats
    return @stats[:member_count]
  end

  def total_points
    @stats = self.stats if !@stats
    return @stats[:total_points]
  end

  def avg_points
    @stats = self.stats if !@stats
    return @stats[:avg_points]
  end

  def include_team_members
    @include_team_members = true
  end

  def handle_status
    if self.status_was != Team::STATUS[:deleted] && self.status == Team::STATUS[:deleted]
      # team was just "deleted" so disband it
      self.disband
    elsif self.status != Team::STATUS[:deleted]
      s =  self.team_members.count >= self.competition.team_size_min ? Team::STATUS[:official] : Team::STATUS[:pending]
      if self.status != s
        self.status = s
        self.save!
        if s == Team::STATUS[:official]
          # official notification
          self.members.each{ |member|
            notify(member, "Your team is now official", "\"<a href='/#/team?team_id=#{self.id}'>#{self.name}</a>\" is now official!", :from => self.leader, :key => "team_#{self.id}_official")
          }
        end
      end
    end
  end

end
