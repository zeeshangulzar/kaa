class Entry < ApplicationModel

  attr_accessible :recorded_on, :exercise_minutes, :exercise_steps, :is_recorded, :notes, :entry_exercise_activities, :entry_behaviors, :entry_gifts, :goal_steps, :goal_minutes, :manually_recorded, :user_id
  # All entries are tied to a user
  belongs_to :user

  many_to_many :with => :exercise_activity, :primary => :entry, :fields => [[:value, :integer]], :order => "id ASC", :allow_duplicates => true

  has_many :entry_behaviors
  has_many :entry_gifts
  accepts_nested_attributes_for :entry_behaviors, :entry_exercise_activities, :entry_gifts

  attr_accessible :entry_behaviors, :entry_exercise_activities, :entry_gifts

  attr_privacy :recorded_on, :exercise_minutes, :exercise_steps, :is_recorded, :notes, :exercise_points, :gift_points, :behavior_points, :updated_at, :entry_behaviors, :entry_gifts, :goal_steps, :goal_minutes, :user_id, :manually_recorded, :me
  
  # Must have the logged on date and user id
  validates_presence_of :recorded_on, :user_id

  # validate
  validate :custom_validation
  
  # Order entries from most recently updated to least recently
  scope :recently_updated, order("`entries`.`updated_at` DESC")
  
  # Get only entries that are available for recording, can't record in the future so don't grab those entries
  scope :available, lambda{ |options|
    sql = "1=1"
    if !options.nil?
      sql += " AND `entries`.`recorded_on` >= '#{options[:start].to_s}' " if !options[:start].nil?
      sql += " AND `entries`.`recorded_on` <= '#{options[:end].to_s}' " if !options[:end].nil?
      sql += " AND `entries`.`recorded_on` = '#{options[:recorded_on].to_s}' " if !options[:recorded_on].nil?
    else
      sql += " AND `entries`.`recorded_on` <= '#{Date.today.to_s}'"
    end
    where(sql).order("`entries`.`recorded_on` DESC").includes(:entry_behaviors, :entry_gifts, :entry_exercise_activities)
  }

  before_save :nullify_exercise_and_set_is_recorded_and_goals
  before_save :calculate_points

  def custom_validation
    user = self.user
    #Entries cannot be in the future, or outside of the started_on and promotion "ends on" range
    if user && self.recorded_on
      if self.recorded_on < self.user.profile.backlog_date
        self.errors[:base] << "Cannot record earlier than user backlog date: " + self.user.profile.backlog_date.to_s
      elsif self.recorded_on > user.promotion.current_date
        self.errors[:base] << "Cannot record later than promotion current date: " + user.promotion.current_date.to_s
      elsif !user.promotion.logging_ends_on.nil? && user.promotion.current_date > user.promotion.logging_ends_on
        self.errors[:base] << "Logging has ended."
      end
    end
    if self.exercise_steps.to_i > 0 && self.exercise_minutes.to_i > 0
      self.errors[:base] << "Cannot log both steps and minutes"
    end
  end

  def nullify_exercise_and_set_is_recorded_and_goals
    self.exercise_steps = 0 if self.exercise_steps.to_i == 0
    self.exercise_minutes = 0 if self.exercise_minutes.to_i == 0
    set_is_recorded
    # update goals from profile
    if self.exercise_steps_was != self.exercise_steps || self.exercise_minutes_was != self.exercise_minutes
      self.goal_minutes = self.user.profile.goal_minutes
      self.goal_steps = self.user.profile.goal_steps
    end
  end

  #Not quite sure the point of this... used to be is_logged
  def set_is_recorded
    write_attribute(:is_recorded, !exercise_minutes.to_i.zero? || !exercise_steps.to_i.zero?)
    true
  end

  def calculate_exercise_points
    points = 0
    value = 0
    point_thresholds = []
    if self.exercise_minutes > 0
      point_thresholds = self.user.promotion.minutes_point_thresholds
      value = self.exercise_minutes
    elsif self.exercise_steps > 0
      point_thresholds = self.user.promotion.steps_point_thresholds
      value = self.exercise_steps
    end

    point_thresholds.each do  |point_threshold|
      if value >= point_threshold.min
        points += point_threshold.value
        break
      end #if
    end #do activity point threshold

    self.exercise_points = points
  end

  def calculate_behavior_points
    points = 0
    point_thresholds = self.user.promotion.behaviors_point_thresholds
    behaviors_logged = 0
    self.entry_behaviors.each{ |entry_behavior|
      if entry_behavior.value && entry_behavior.value.to_i > 0
        behaviors_logged += 1
      end
    }
    point_thresholds.each{ |point_threshold|
      if behaviors_logged >= point_threshold.min
        points = point_threshold.value
        break
      end
    }
    self.behavior_points = points
  end

  def calculate_gift_points
    points = 0
    point_thresholds = self.user.promotion.gifts_point_thresholds
    gifts_logged = 0
    self.entry_gifts.each{ |entry_gift|
      if entry_gift.value && entry_gift.value.to_i > 0
        gifts_logged += 1
      end
    }
    point_thresholds.each{ |point_threshold|
      if gifts_logged >= point_threshold.min
        points = point_threshold.value
        break
      end
    }
    self.gift_points = points
  end

  def calculate_points
    calculate_exercise_points
    calculate_behavior_points
    calculate_gift_points
  end

  def as_json(options={})
    options[:meta] ||= false
    super
  end

  def self.aggregate(options={})
    sql = "
  -- steps/minutes summary
  SELECT
    YEAR(entries.recorded_on) AS year,
    MONTH(entries.recorded_on) AS month,
    SUM(entries.exercise_minutes) AS total_minutes,
    SUM(entries.exercise_steps) AS total_steps,
    AVG(entries.exercise_minutes) AS avg_minutes,
    AVG(entries.exercise_steps) AS avg_steps,
    NULL AS behavior_id,
    NULL AS total_behavior,
    NULL AS avg_behavior,
    NULL as exercise_activity_id,
    NULL AS total_activity,
    NULL AS avg_activity,
    'all' AS type
  FROM entries
  WHERE
    entries.user_id = #{options[:user_id]}
    AND YEAR(entries.recorded_on) = #{options[:year]}
  GROUP BY
    YEAR(entries.recorded_on), MONTH(entries.recorded_on)
UNION
  -- entry behaviors
  SELECT
    YEAR(entries.recorded_on) AS year,
    MONTH(entries.recorded_on) AS month,
    NULL AS total_minutes,
    NULL AS total_steps,
    NULL AS avg_minutes,
    NULL AS avg_steps,
    entry_behaviors.behavior_id,
    SUM(entry_behaviors.value) AS total_behavior,
    AVG(entry_behaviors.value) AS avg_behavior,
    NULL AS exercise_activity_id,
    NULL AS total_activity,
    NULL AS avg_activity,
    'behavior' AS type
  FROM entries
  JOIN entry_behaviors ON entry_behaviors.entry_id = entries.id
  WHERE
    entries.user_id = #{options[:user_id]}
    AND YEAR(entries.recorded_on) = #{options[:year]}
  GROUP BY
    YEAR(entries.recorded_on), MONTH(entries.recorded_on), entry_behaviors.behavior_id
UNION
  -- entry exercise activities
  SELECT
    YEAR(entries.recorded_on) AS year,
    MONTH(entries.recorded_on) AS month,
    NULL AS total_minutes,
    NULL AS total_steps,
    NULL AS avg_minutes,
    NULL AS avg_steps,
    NULL AS behavior_id,
    NULL AS total_behavior,
    NULL AS avg_behavior,
    rel_entries_exercises_activities.exercise_activity_id,
    SUM(rel_entries_exercises_activities.value) AS total_activity,
    AVG(rel_entries_exercises_activities.value) AS avg_activity,
    'activity' AS type
  FROM entries
  JOIN rel_entries_exercises_activities ON rel_entries_exercises_activities.entry_id = entries.id
  WHERE
    entries.user_id = #{options[:user_id]}
    AND YEAR(entries.recorded_on) = #{options[:year]}
  GROUP BY
    YEAR(entries.recorded_on), MONTH(entries.recorded_on), rel_entries_exercises_activities.exercise_activity_id
    "
    rows = connection.select_all(sql)
    summary = []
    rows.each{|row|
      m = row['month'] - 1
      if !summary[m].present?
        summary[m] = {
          :total_minutes => 0,
          :avg_minutes   => 0,
          :total_steps   => 0,
          :avg_steps     => 0,
          :behaviors     => [],
          :activities    => []
        }
      end
      
      case row['type']
        when 'all'
          summary[m][:total_minutes] = row['total_minutes']
          summary[m][:avg_minutes]  = row['avg_minutes']
          summary[m][:total_steps]   = row['total_steps']
          summary[m][:avg_steps]     = row['avg_steps']
        when 'behavior'
          bsum = {
            :behavior_id => row['behavior_id'],
            :total       => row['total_behavior'],
            :avg         => row['avg_behavior']
          }
          summary[m][:behaviors].push(bsum)
        when 'activity'
          asum = {
            :exercise_activity_id => row['exercise_activity_id'],
            :total                => row['total_activity'],
            :avg                  => row['avg_activity']
          }
          summary[m][:activities].push(asum)
      end
    }
    return summary
  end

  before_save :check_for_changes
  after_commit :team_member_update
  after_commit :update_user_points

  # whether or not we should publish the user object to redis & update team scores
  def check_for_changes
    publish = false
    activity_columns = ['exercise_minutes', 'exercise_steps']
    points_columns = ['exercise_points', 'gift_points', 'behavior_points']
    columns_to_check = activity_columns + points_columns
    columns_to_check.each{|column|
      Rails.logger.warn("#{column} is: #{self.send(column).to_i} was: #{self.send(column + "_was").to_i}")
      if self.send(column).to_i != self.send(column + "_was").to_i
        publish = true
        if points_columns.include?(column)
          #self.team_member_update
        end
      end
    }

    # check for changed exercise activities
    eas = self.exercise_activities.collect{|ea|ea.id}
    ras = self.user.recent_activities(true)
    new_ras = eas.reject{ |ea| ras.include?(ea) }
    if !new_ras.empty?
      publish = true
    end

    if publish
      u = self.user
      u.attach('stats', u.stats())
      $redis.publish('userUpdated', u.as_json.to_json)
    end
  end

  def team_member_update
    # update user's team member points if they're on a team in an active competition, see user model
    Rails.logger.warn "UPDATING TEAM POINTS!"
    self.user.update_team_member_points()
  end

  def update_user_points
    # update user's aggregate point totals
    self.user.update_points()
  end
end
