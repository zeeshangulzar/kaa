class Competition < ApplicationModel

  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :enrollment_starts_on, :enrollment_ends_on, :competition_starts_on, :competition_ends_on, :active, :name, :team_size_min, :team_size_max, :promotion_id, :freeze_team_scores_on, :public
  attr_privacy :freeze_team_scores, :master
  
  # Associations
  belongs_to :promotion
  
  has_many :teams, :order => "name ASC"
  has_many :official_teams, :class_name => "Team", :conditions => {:status => Team::STATUS[:official]}, :order => "name ASC"
  has_many :pending_teams, :class_name => "Team", :conditions => {:status => Team::STATUS[:pending]}, :order => "name ASC"
  has_many :members, :class_name => "TeamMember"

  ASSOCIATED_CACHE_SYMBOLS = [:current_competition] # custom names used in other models' attr_privacy (e.g. Promotion) that represent an association and require clearing the parent model cache
  
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

  def leaderboard(conditions = {}, count = false)

    # filter junk out...
    sort_columns = ['teams.name', 'teams.status', 'avg_points', 'total_points', 'member_count']
    conditions.delete(:sort) if !conditions[:sort].nil? && !sort_columns.include?(conditions[:sort])
    conditions.delete(:sort_dir) if !conditions[:sort_dir].nil? && !['ASC', 'DESC'].include?(conditions[:sort_dir].upcase)
    conditions.delete(:offset) if !ApplicationHelper::is_i?(conditions[:offset])
    conditions.delete(:limit) if !ApplicationHelper::is_i?(conditions[:limit])
    conditions.delete(:status) if !conditions[:status].nil? && !Team::STATUS.keys.include?(conditions[:status].downcase.to_sym)

    conditions = {
      :offset       => nil,
      :limit        => 99999999999, # if we have more teams than this, we've got bigger problems to worry about
      :location_ids => [],
      :status       => nil,
      :sort         => "avg_points",
      :sort_dir     => "DESC",
      :neighbors_id => nil
    }.nil_merge!(conditions)

    teams_sql = "
      SELECT
    "
    if count
      teams_sql = teams_sql + " COUNT(DISTINCT(teams.id)) AS team_count"
    else
      teams_sql = teams_sql + "
        teams.id, teams.name, teams.image, teams.motto, teams.status,
        SUM(members.total_points) AS total_points,
        SUM(members.total_points)/COUNT(DISTINCT(members.user_id)) AS avg_points,
        COUNT(DISTINCT(members.user_id)) AS member_count
      "
    end
    teams_sql = teams_sql + "
      FROM teams
        JOIN competitions ON competitions.id = teams.competition_id
        #{"JOIN team_members AS members ON members.team_id = teams.id" if !count}
        #{"JOIN team_members AS leader_member ON leader_member.team_id = teams.id AND leader_member.is_leader = 1 JOIN users AS leader ON leader.id = leader_member.user_id" if !conditions[:location_ids].empty?}
      WHERE
        teams.competition_id = #{self.id}
        #{"AND teams.status = #{Team::STATUS[conditions[:status].to_sym]}" if !conditions[:status].nil?}
        #{"AND (leader.location_id IN (#{conditions[:location_ids].join(',')}) OR leader.top_level_location_id IN (#{conditions[:location_ids].join(',')}))" if !conditions[:location_ids].empty?}
    "
    if !count
      teams_sql = teams_sql + "
        GROUP BY teams.id
        ORDER BY #{conditions[:sort]} #{conditions[:sort_dir]}
        #{"LIMIT " + conditions[:offset].to_s + ", " + conditions[:limit].to_s if !conditions[:offset].nil? && !conditions[:limit].nil?}
        #{"LIMIT " + conditions[:limit].to_s if conditions[:offset].nil? && !conditions[:limit].nil?}
      "
    end
    result = self.connection.exec_query(teams_sql)
    if count
      return result.first['team_count']
    end
    teams = []
    
    rank = 0
    team_count = !conditions[:offset].nil? ? conditions[:offset].to_i : 0
    previous_team = nil
    neighbors_index = nil
    result.each{|row|
      team_count += 1
      team = {}
      team['image']        = {}
      team['id']           = row['id']
      team['image']['url'] = row['image'].nil? ? TeamImageUploader::default_url : TeamImageUploader::asset_host_url + row['image'].to_s
      team['name']         = row['name']
      team['motto']        = row['motto']
      team['total_points'] = row['total_points']
      team['avg_points']   = row['avg_points']
      team['status']       = row['status']
      team['member_count'] = row['member_count']
      rank = team_count if (!previous_team || previous_team['avg_points'] > team['avg_points'])
      team['rank']         = rank
      teams << team
      previous_team = team
      if conditions[:neighbors_id] && team['id'].to_s == conditions[:neighbors_id].to_s
        neighbors_index = teams.index(team)
      end
    }

    return [] if teams.empty? # this is a rather important line

    if neighbors_index
      start = [0, neighbors_index.to_i - 2].max
      teams = teams.slice(start, 5)
    end

    # grab users of posts, replies and likes..
    users_sql = "
      SELECT
        users.id AS user_id, users.top_level_location_id, profiles.id AS profile_id, profiles.first_name, profiles.last_name, profiles.image,
        locations.id AS location_id, locations.name AS location_name, team_members.team_id
      FROM users
        JOIN profiles ON profiles.user_id = users.id
        JOIN team_members ON team_members.user_id = users.id
        LEFT JOIN locations ON locations.id = users.location_id
      WHERE
        team_members.team_id IN (#{(teams.collect{|t|t['id']}).join(',')}) AND team_members.is_leader = 1
    "
    result = self.connection.exec_query(users_sql)
    users = []
    users_idx = {}
    result.each{|row|
      user = {}
      user['id']                      = row['user_id']
      user['top_level_location_id']   = row['top_level_location_id']
      user['profile']                 = {}
      user['profile']['image']        = {}
      user['location']                = {}
      user['profile']['id']           = row['profile_id']
      user['profile']['first_name']   = row['first_name']
      user['profile']['last_name']    = row['last_name']
      user['profile']['image']['url'] = row['image'].nil? ? ProfilePhotoUploader::default_url : ProfilePhotoUploader::asset_host_url + row['image'].to_s
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

  def update_all_team_member_points
    sql = "
      UPDATE team_members
      LEFT JOIN (
        SELECT
          SUM(COALESCE(entries.behavior_points, 0) + COALESCE(entries.exercise_points, 0)) AS total_points, 
          SUM(entries.exercise_points) AS total_exercise_points, 
          SUM(entries.behavior_points) AS total_behavior_points,
          user_id
        FROM entries
        WHERE entries.recorded_on BETWEEN '#{self.competition_starts_on}' AND '#{self.competition_ends_on}'
        GROUP BY user_id
        ) stats on stats.user_id = team_members.user_id
      SET
        team_members.total_points = COALESCE(stats.total_points, 0),
        team_members.total_exercise_points = COALESCE(stats.total_exercise_points, 0),
        team_members.total_behavior_points = COALESCE(stats.total_behavior_points, 0)
    "
    self.connection.execute(sql)
  end

  def all_team_photos
    sql = "
      SELECT
        photos.id AS photo_id, photos.caption, photos.image,
        users.id AS user_id,
        profiles.first_name, profiles.last_name
      FROM photos
        JOIN teams ON photos.photoable_type = 'Team' AND photos.photoable_id = teams.id
        JOIN users ON users.id = photos.user_id
        JOIN profiles ON profiles.user_id = users.id
      WHERE
        teams.competition_id = #{self.id}
      ORDER BY photos.created_at DESC
    "
    result = self.connection.exec_query(sql)
    photos = []
    result.each{ |row|
      photo = {}
      photo[:user] = {}
      photo[:user][:profile] = {}
      photo[:image] = {}
      photo[:image][:large_thumbnail] = {}

      photo[:id]                              = row['photo_id']
      photo[:caption]                         = row['caption']
      photo[:image][:large_thumbnail][:url]   = row['image'].nil? ? PhotoImageUploader::default_url : PhotoImageUploader::asset_host_url + 'large_thumbnail_' + row['image'].to_s
      photo[:image][:url]                     = row['image'].nil? ? PhotoImageUploader::default_url : PhotoImageUploader::asset_host_url + row['image'].to_s
      photo[:user][:id]                       = row['user_id']
      photo[:user][:profile][:first_name]     = row['first_name']
      photo[:user][:profile][:last_name]      = row['last_name']
      
      photos << photo
    }
    return photos
  end
  
end
