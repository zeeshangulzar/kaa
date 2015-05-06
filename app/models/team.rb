class Team < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :name, :motto, :image, :leader, :total_points, :avg_points, :member_count, :status, :any_user

  has_many :team_members
  has_many :members, :through => :team_members, :source => :user
  has_many :team_invites
  has_one :leader, :through => :team_members, :source => :user, :conditions => "is_leader = 1"

  validates_presence_of :name

  validates_uniqueness_of :name, :scope => :competition_id

  mount_uploader :image, TeamImageUploader

  has_wall

  STATUS = {
    :pending => 0,
    :official => 1
  }

  def as_json(options={})
    team_json = super(options.merge(:do_not_paginate=>['team_members']))
    team_json['team_members'] = self.team_members.as_json if @include_team_members
    return team_json
  end

  def leader
    unless self.team_members.where(:is_leader => 1).empty?
      return self.team_members.where(:is_leader => 1).first.user
    end
    return nil
  end

  def disband
    team.members.each do |member|
      member.notifications.find(:all, :conditions => ["message like ?", "%join a #{Team::Title}: #{team.name}</a>."]).each{|x| x.destroy}
      member.add_notification("#{team.name} has been disbanded.  You can join or start a different team.")
      reset_user_app_menu(member) #redraw menu so that user can access team links
    end
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

end
