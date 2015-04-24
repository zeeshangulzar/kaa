class Competition < ApplicationModel

  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :enrollment_starts_on, :enrollment_ends_on, :competition_starts_on, :competition_ends_on, :active, :name, :public
  
  # Associations
  belongs_to :promotion
  
  has_many :teams, :order => "name ASC"
  has_many :official_teams, :class_name => "Team", :conditions => {:status => Team::STATUS[:official]}, :order => "name ASC"
  has_many :pending_teams, :class_name => "Team", :conditions => {:status => Team::STATUS[:pending]}, :order => "name ASC"
  

  maintain_sequence :scope=>:promotion_id, :order=>:competition_starts_on

  
  def during_enrollment?(dte=promotion.current_date)
    dte.between?(enrollment_starts_on,enrollment_ends_on)
  end

  def during_competition?(dte=promotion.current_date)
    dte.between?(competition_starts_on,competition_ends_on)
  end

  def after_competition?(dte=promotion.current_date)
    dte > competition_ends_on
  end

  def freeze_team_scores_on
    competition_ends_on + freeze_team_scores
  end
  
  def total_comp_days
    [Date.today, competition_ends_on].min - [competition_starts_on, Date.today].min + 1
  end
  
  def has_strict_team_size?
    team_size_min == team_size_max
  end
  
  def allows_unlimited_team_size?
    team_size_max.nil?
  end
  
  def team_size_message
    if has_strict_team_size?
      team_size_min
    elsif allows_unlimited_team_size?
      "#{team_size_min} or more"
    else
      "#{team_size_min}-#{team_size_max}"
    end
  end


  # big ass method to get everything on the wall without active record junk
  # it's ugly, but it's fast...
  def leaderboard(conditions = {}, count = false)
    conditions = {
      :offset       => 0,
      :limit        => 50,
      :location_ids => []
    }.merge(conditions)

    # get top posts, all of the various conditions are applied here
    teams_sql = "
      SELECT
        teams.id, teams.name, teams.image, teams.motto, teams.status,
        SUM(exercise_points + challenge_points + timed_behavior_points) AS total_points,
        SUM(exercise_points + challenge_points + timed_behavior_points)/COUNT(DISTINCT(team_members.user_id)) AS avg_points,
        COUNT(DISTINCT(team_members.user_id)) AS member_count
      FROM teams
        JOIN competitions ON competitions.id = teams.competition_id
        JOIN team_members ON team_members.team_id = teams.id
        LEFT JOIN entries ON team_members.user_id = entries.user_id AND competitions.competition_starts_on <= entries.recorded_on AND competitions.competition_ends_on >= entries.recorded_on
      WHERE
        teams.competition_id = #{self.id}
        AND teams.status = #{Team::STATUS[:official]}
      GROUP BY teams.id
      ORDER BY avg_points DESC
    "
    result = self.connection.exec_query(teams_sql)
    teams = []
    result.each{|row|
      team = {}
      team['image']        = {}
      team['id']           = row['id']
      team['image']['url'] = row['image'].nil? ? TeamImageUploader::default_url : TeamImageUploader::asset_host_url + row['photo'].to_s
      team['name']         = row['name']
      team['motto']        = row['motto']
      team['total_points'] = row['total_points']
      team['avg_points']   = row['avg_points']
      team['status']       = row['status'] # TODO: shouldn't need this, should we?
      team['member_count'] = row['member_count']
      teams << team
    }

    return [] if teams.empty? # this is a rather important line

    # grab users of posts, replies and likes..
    users_sql = "
      SELECT
        users.id AS user_id, profiles.id AS profile_id, profiles.first_name, profiles.last_name, profiles.image,
        locations.id AS location_id, locations.name AS location_name, team_members.team_id
      FROM users
        JOIN profiles ON profiles.user_id = users.id
        JOIN locations ON locations.id = users.location_id
        JOIN team_members ON team_members.user_id = users.id
      WHERE
        team_members.team_id IN (#{(teams.collect{|t|t['id']}).join(',')}) AND team_members.is_leader = 1
    "
    result = self.connection.exec_query(users_sql)
    users = []
    users_idx = {}
    result.each{|row|
      user = {}
      user['id']                      = row['user_id']
      user['profile']                 = {}
      user['profile']['image']        = {}
      user['location']                = {}
      user['profile']['id']           = row['profile_id']
      user['profile']['first_name']   = row['first_name']
      user['profile']['last_name']    = row['last_name']
      user['profile']['image']['url'] = row['image'].nil? ? ProfilePhotoUploader::default_url : ProfilePhotoUploader::asset_host_url + row['image'].to_s
      user['milestone_id']            = row['milestone_id']
      user['location_id']             = row['location_id']
      user['location']['id']          = row['location_id']
      user['location']['name']        = row['location_name']

      users_idx[row['team_id']] = user

      users << user
    }

    # attaching users (leaders) to teams..
    teams.each_with_index{|team, index|
      teams[index]['leader'] = users_idx[team['id']]
    }

    # all done!
    return teams
  end
end
