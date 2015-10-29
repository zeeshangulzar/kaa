require 'bcrypt'

class User < ApplicationModel
  include HESFitbitUserAdditions
  include HESJawboneUserAdditions
  include PerModelEncryption

  flags :hide_goal_hit_message, :default => false
  flags :has_seen_tutorial, :default => false
  flags :has_seen_team_tutorial, :default => false
  flags :has_been_home, :default => false
  flags :has_been_to_summary, :default => false
  flags :notify_email_teams, :default => true
  flags :allow_daily_emails_monday, :default => false
  flags :allow_daily_emails_all_week, :default => true
  flags :has_seen_wellness_pdf, :default => false

  flags :stay_logged_in, :default => true

  attr_privacy_no_path_to_user

  acts_as_notifier
  
  Role = {
    :user                       => "User",
    :location_coordinator       => "Location Coordinator",
    :regional_coordinator       => "Regional Coordinator",
    :coordinator                => "Coordinator",
    :reseller                   => "Reseller",
    :poster                     => "Poster",
    :master                     => "Master",
  }

  has_many :requests, :order => "created_at DESC"
  after_commit :welcome_email, :on => :create
  after_commit :check_for_invites, :on => :create

  def welcome_email
    Resque.enqueue(WelcomeEmail, self.id)
  end

  def welcome_notification
    notify(self, "User Created", "Welcome to <em>#{Constant::AppName}</em>! You will receive important notifications here.", :from => self, :key => "user_#{id}")
  end

  def check_for_invites
    if self.promotion.current_competition
      invites = TeamInvite.includes(:team, :competition).where("`team_invites`.`email` = '#{self.email}' AND `team_invites`.`user_id` IS NULL AND `competitions`.`promotion_id` = #{self.promotion_id}")
      invites.each{|invite|
        invite.user_id = self.id
        invite.save!
      }
    end
  end

  can_post
  can_like
  can_share
  can_rate
  has_notifications
  has_photos

  # relationships
  has_one :profile, :dependent => :destroy
  has_one :demographic, :dependent => :destroy

  has_one :eligibility
  after_destroy :reset_eligibility

  # attrs
  attr_protected :role, :auth_key
  
  attr_privacy :email, :profile, :public
  attr_privacy :location, :top_level_location_id, :promotion_id, :any_user
  attr_privacy :username, :flags, :role, :active_device, :altid, :last_accessed, :allows_email, :location_id, :top_level_location_id, :backdoor, :opted_in_individual_leaderboard, :me
  attr_privacy :nuid_verified, :master

  attr_accessible :username, :email, :username, :altid, :promotion_id, :password, :profile, :profile_attributes, :flags, :location_id, :top_level_location_id, :active_device, :last_accessed, :role, :opted_in_individual_leaderboard

  # validation
  validates_presence_of :email, :role, :promotion_id, :organization_id, :reseller_id, :password
  validates_uniqueness_of :email, :scope => :promotion_id

  belongs_to :promotion
  belongs_to :location
  has_many :entries, :order => :recorded_on, :dependent => :destroy
  has_many :evaluations, :dependent => :destroy
  has_many :orders, :dependent => :destroy

  accepts_nested_attributes_for :profile, :evaluations
  attr_accessor :include_evaluation_definitions
  
  # hooks
  after_initialize :set_default_values, :if => 'new_record?'
  before_validation :set_parents, :on => :create
  before_save :set_top_level_location


  # includes
  include HESUserMixins
  include BCrypt

  # methods
  def set_default_values
    self.role ||= Role[:user]
    self.auth_key ||= SecureRandom.hex(40)
  end

  def set_parents
    if self.promotion && self.promotion.organization
      self.organization_id = self.promotion.organization_id
      self.reseller_id = self.promotion.organization.reseller_id
    end
  end

  def set_top_level_location
    unless !self.location_id
      self.top_level_location_id = Location.find(self.location_id).top_location.id
    end
  end
  
  def auth_basic_header
    b64 = Base64.encode64("#{self.id}:#{self.auth_key}").gsub("\n","")
    "Basic #{b64}"
  end

  def has_made_self_known_to_public?
    return true
  end

  def password
    return nil if !self.password_hash
    @password ||= Password.new(self.password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  # Gets the next evaluation definition for a user
  # @return [EvaluationDefinition] evaluation definition that hasn't been completed
  def get_next_evaluation_definition
    return @next_eval_definition if @next_eval_definition

    eval_definations = self.evaluations.collect{|x| x.definition}
    @next_eval_definition = (promotion.evaluation_definitions - eval_definations).first

    @next_eval_definition
  end

  def search(search, unassociated = false, limit = 0, promotion_id = self.promotion_id)
    search = self.connection.quote_string(search)
    sql = "
      SELECT
        users.*
      FROM users
      JOIN profiles ON profiles.user_id = users.id
      WHERE
      (
        users.email LIKE '%#{search}%'
        OR profiles.first_name like '#{search}%'
        OR profiles.last_name like '%#{search}%'
        OR CONCAT(profiles.first_name, ' ', profiles.last_name) LIKE '#{search}%'
      )
      AND
      (
        users.id <> #{self.id}
        AND users.promotion_id = #{promotion_id}
      )
      GROUP BY users.id
      ORDER BY profiles.last_name
      #{'LIMIT ' + limit.to_s if limit > 0}
    "
    users = User.find_by_sql(sql)
    ActiveRecord::Associations::Preloader.new(users, :profile).run
    return users
  end

  def self.stats(user_ids,year)
    user_ids = [user_ids] unless user_ids.is_a?(Array)
    user = self
    sql = "
      SELECT
      entries.user_id AS user_id,
      SUM(exercise_points) AS total_exercise_points,
      SUM(gift_points) AS total_gift_points,
      SUM(behavior_points) AS total_behavior_points,
      SUM(exercise_steps) AS total_exercise_steps,
      SUM(exercise_minutes) AS total_exercise_minutes,
      SUM(exercise_points) + SUM(gift_points) + SUM(behavior_points) AS total_points,
      AVG(exercise_minutes) AS average_exercise_minutes,
      AVG(exercise_steps) AS average_exercise_steps
      FROM
      entries
      WHERE
      user_id in (#{user_ids.join(',')})
      AND YEAR(recorded_on) = #{year}
      GROUP BY user_id
    "
    # turns [1,2,3] into {1=>{},2=>{},3=>{}} where each sub-hash is missing data (to be replaced by query)
    keys = ['total_exercise_points','total_gift_points','total_behavior_points','total_exercise_steps','total_exercise_minutes','total_points','average_exercise_minutes','average_exercise_steps']
    zeroes = Hash[*keys.collect{|k|[k,0]}.flatten]
    user_stats = Hash[*user_ids.collect{|id|[id,zeroes]}.flatten]
    self.connection.select_all(sql).each do |row|
      user_stats[row['user_id'].to_i] = row
    end
    return user_stats
  end

  def stats(year = self.promotion.current_date.year)
    unless @stats
      arr =  self.class.stats([self.id],year)
      @stats = arr[self.id]
    end
    return @stats
  end

  def location_ids
    # a helper method to return all location ids of a user..
    # right now it's just 2, but in theory it could be more
    # so this can return a flattened array of all ids
    return [self.location_id,self.top_level_location_id]
  end

  def email_with_name
    return "#{self.profile.full_name} <#{self.email}>"
  end

  def active_evaluation_definition_ids
    unless @active_evaluation_definition_ids
      @active_evaluation_definition_ids = EvaluationDefinition.active_with_user(self).reload.collect{|ed|ed.id}
    end
    return @active_evaluation_definition_ids
  end

  def active_evaluation_definition_ids=(array)
    @active_evaluation_definition_ids = array
  end

  def completed_evaluation_definition_ids
    unless @completed_evaluation_definition_ids
      @completed_evaluation_definition_ids = self.evaluations.collect{|e|e.evaluation_definition_id}
    end
    return @completed_evaluation_definition_ids
  end

  def completed_evaluation_definition_ids=(array)
    @completed_evaluation_definition_ids = array
  end

  def process_last_accessed
    self.update_attributes(:last_accessed => self.promotion.current_time) if !self.last_accessed || self.last_accessed.to_date < self.promotion.current_date
  end

  def current_team
    return nil if self.promotion.current_competition.nil?
    current_competition_id = self.promotion.current_competition.id
    teams = Team.includes(:team_members).where("team_members.user_id = #{self.id} AND team_members.competition_id = #{current_competition_id} AND teams.competition_id = #{current_competition_id} AND teams.status <> #{Team::STATUS[:deleted]}")
    return teams.first
  end

  def current_team_member
    return nil if !self.current_team
    return current_team.team_members.where(:user_id => self.id).first
  end

  def team_invites(type = nil)
    return nil if self.promotion.current_competition.nil?
    current_competition_id = self.promotion.current_competition.id
    invites = TeamInvite.where("team_invites.user_id = #{self.id} AND team_invites.competition_id = #{current_competition_id} #{ "AND team_invites.invite_type = '#{TeamInvite::TYPE[type.to_sym]}'" if !type.nil?}")
    return invites
  end

  def team_id=(team_id)
    @team_id = team_id
  end

  def update_team_member_points
    if !self.current_team_member.nil? && self.promotion.current_date <= self.promotion.current_competition.freeze_team_scores_on
      self.current_team_member.update_points
    end
  end

  def ids_of_connections
    ids = []
    if self.current_team
      sql = "
        SELECT
          DISTINCT(connection_id) AS id
        FROM (
          SELECT
            DISTINCT(team_members.user_id) AS connection_id
          FROM team_members
          JOIN teams ON teams.id = team_members.team_id
          WHERE
            team_members.team_id = #{self.current_team.id} AND teams.competition_id = #{self.current_team.competition_id}
        ) AS connections
      "
      result = self.connection.exec_query(sql)
      result.each{ |row|
        ids << row['id']
      }
    end
    return ids
  end

  def self.get_team_ids(user_ids = [])
    return {} if user_ids.empty?
    sql = "
      SELECT
        team_members.user_id, teams.id
      FROM teams
      JOIN team_members ON teams.id = team_members.team_id AND teams.status <> #{Team::STATUS[:deleted]}
      WHERE
        team_members.user_id IN (#{user_ids.join(',')})
    "
    result = self.connection.exec_query(sql)
    ids = {}
    user_ids.each{|id|
      ids[id.to_i] = nil
    }
    result.each{ |row|
      ids[row['user_id']] = row['id']
    }
    return ids
  end

  def get_fitbit_weeks
    if self.entries.count > 0
      last_day = [Date.today, self.entries.last.recorded_on].min
    else
      last_day = Date.today
    end

    days = self.profile.started_on..last_day
    weeks = (days.to_a.size / 7.0).ceil

    opts = []

    weeks.times do |week|
      mon = self.profile.started_on + (week * 7)
      sun = mon + 6
      opts << ["Week #{week + 1}: #{mon.strftime('%B %e')} - #{sun.strftime('%B %e')}", week]
    end

    opts
  end

  # not used in h4h...
  def recent_activities(id_only = false, limit = 5)
    sql = "
      SELECT
        DISTINCT(exercise_activities.id) AS id
      FROM entries
      JOIN rel_entries_exercises_activities ON rel_entries_exercises_activities.entry_id = entries.id
      JOIN exercise_activities ON exercise_activities.id = rel_entries_exercises_activities.exercise_activity_id
      WHERE
        entries.user_id = #{self.id}
        AND entries.recorded_on <= '#{self.promotion.current_date}'
      GROUP BY exercise_activities.id
      ORDER BY MAX(rel_entries_exercises_activities.updated_at) DESC
      LIMIT #{limit}
    "
    result = self.connection.exec_query(sql)
    ids = []
    result.each{ |row|
      ids << row['id']
    }
    if id_only  
      return ids
    end
    return ExerciseActivity.find(ids)
  end

  def update_points
    sql = "
      UPDATE users
      JOIN (
        SELECT
          user_id,
          SUM(COALESCE(entries.behavior_points, 0) + COALESCE(entries.exercise_points, 0) + COALESCE(entries.gift_points, 0)) AS total_points,
          SUM(entries.exercise_points) AS total_exercise_points,
          SUM(entries.behavior_points) AS total_behavior_points,
          SUM(entries.gift_points) AS total_gift_points
        FROM entries
        WHERE
          user_id = #{self.id}
          AND entries.recorded_on BETWEEN '#{self.promotion.starts_on}' AND '#{[self.promotion.ends_on, self.promotion.current_date].min}'
        ) stats on stats.user_id = users.id
      SET
        users.total_points = COALESCE(stats.total_points, 0),
        users.total_exercise_points = COALESCE(stats.total_exercise_points, 0),
        users.total_behavior_points = COALESCE(stats.total_behavior_points, 0),
        users.total_gift_points = COALESCE(stats.total_gift_points, 0)
    "
    self.connection.execute(sql)
  end

  def reset_eligibility
    self.eligibility.update_attributes(:user_id => nil) if !self.eligibility.nil?
  end

end
