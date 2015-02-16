class Entry < ApplicationModel

  attr_accessible :recorded_on, :exercise_minutes, :exercise_steps, :is_recorded, :notes, :entry_exercise_activities, :entry_behaviors, :goal_steps, :goal_minutes
  # All entries are tied to a user
  belongs_to :user

  many_to_many :with => :exercise_activity, :primary => :entry, :fields => [[:value, :integer]], :order => "id ASC", :allow_duplicates => true

  has_many :entry_behaviors, :in_json => true
  accepts_nested_attributes_for :entry_behaviors, :entry_exercise_activities

  attr_accessible :entry_behaviors, :entry_exercise_activities

  attr_privacy :recorded_on, :exercise_minutes, :exercise_steps, :is_recorded, :notes, :exercise_points, :challenge_points, :timed_behavior_points, :updated_at, :entry_exercise_activities, :entry_behaviors, :goal_steps, :goal_minutes, :user_id, :me
  
  # Can not have the same recorded on date for one user
#  validates_uniqueness_of :recorded_on, :scope => :user_id
  
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
    where(sql).order("`entries`.`recorded_on` DESC").includes(:entry_behaviors, :entry_exercise_activities)
  }

  before_save :calculate_points
  before_save :nullify_exercise

  after_save    :do_milestone_badges
  after_destroy :do_milestone_badges
  after_save    :do_weekend_badges
  after_destroy :do_weekend_badges
  after_save :publish_to_redis
  
  def custom_validation
    user = self.user
    #Entries cannot be in the future, or outside of the started_on and promotion "ends on" range
    if user && self.recorded_on
      if self.recorded_on < user.profile.started_on
        self.errors[:base] << "Cannot record earlier than user start date: " + user.profile.started_on.to_s
      elsif self.recorded_on < self.user.profile.backlog_date
        self.errors[:base] << "Cannot record earlier than user backlog date: " + self.user.promotion.backlog_date.to_s
      elsif self.recorded_on > user.promotion.current_date
        self.errors[:base] << "Cannot record later than promotion current date: " + user.promotion.current_date.to_s
      end
    end
    if self.exercise_steps.to_i > 0 && self.exercise_minutes.to_i > 0
      self.errors[:base] << "Cannot log both steps and minutes"
    end
  end

  def nullify_exercise
    self.exercise_steps = nil if self.exercise_steps.to_i == 0
    self.exercise_minutes = nil if self.exercise_minutes.to_i == 0
  end

  def write_attribute_with_exercise(attr,val)
    write_attribute_without_exercise(attr,val)
    if [:exercise_minutes,:exercise_steps].include?(attr.is_a?(String) ? attr.to_sym : attr) && !self.user.nil?
      calculate_exercise_points
      # set_is_recorded
    end
  end

  alias_method_chain :write_attribute,:exercise

  #Not quite sure the point of this... used to be is_logged
  def set_is_recorded
    write_attribute(:is_recorded, !exercise_minutes.to_i.zero? || !exercise_steps.to_i.zero?)
    true
  end

  def calculate_exercise_points
    points = 0
    value = 0
    point_thresholds = []
    if !self.exercise_minutes.nil?
      point_thresholds = self.user.promotion.minutes_point_thresholds
      value = self.exercise_minutes
    elsif !self.exercise_steps.nil?
      point_thresholds = self.user.promotion.steps_point_thresholds
      value = self.exercise_steps
    end

    point_thresholds.each do |point_threshold|
      if value >= point_threshold.min
        points += point_threshold.value
        break
      end #if
    end #do activity point threshold

    self.exercise_points = points
  end

  def calculate_points
    calculate_exercise_points

    timed_behavior_points = 0
    self.entry_behaviors.each do |entry_behavior|
      behavior = entry_behavior.behavior

      if entry_behavior.value
        value = entry_behavior.value.to_i
        value = behavior.cap_value && value >= behavior.cap_value ?  behavior.cap_value : value

        #Timed behaviors override behavior
        if behavior.active_timed_behavior
          behavior.active_timed_behavior.point_thresholds do |point_threshold|
            if value >= point_threshold.min
              timed_behavior_points += point_threshold.value
            end #if
          end #do timed point threshold
        end #elsif
      end #if
    end #do entry_behavior

    self.timed_behavior_points = timed_behavior_points

    #Challenge Points Calculation

    # sent challenges during this recording week not including today
    challenges_sent_this_week = self.user.challenges_sent.where("DATE(created_at) <> ? AND DATE(created_at) >= ? AND DATE(created_at) <= ?", self.recorded_on, self.recorded_on.beginning_of_week, self.recorded_on.end_of_week) rescue []
    # how many challenges sent can count towards points based on what's already been sent this week?
    max_sent_countable = challenges_sent_this_week.empty? ? self.user.promotion.max_challenges_sent : [self.user.promotion.max_challenges_sent, challenges_sent_this_week.size].min
    # today's sent challenges
    challenges_sent_today = !self.user.challenges_sent.empty? ? self.user.challenges_sent.where("DATE(created_at) = ?", self.recorded_on) : nil
    challenges_sent_countable = 0
    if !challenges_sent_today.nil? && !challenges_sent_today.empty?
      challenges_sent_countable = (challenges_sent_today.size > max_sent_countable) ? max_sent_countable : challenges_sent_today.size
    end
    challenges_sent_points = challenges_sent_countable * self.user.promotion.challenges_sent_points

    # completed challenges not including today
    challenges_completed_this_week = self.user.challenges_received.where("DATE(completed_on) <> ? AND DATE(completed_on) >= ? AND DATE(completed_on) <= ?", self.recorded_on, self.recorded_on.beginning_of_week, self.recorded_on.end_of_week) rescue []
    # how many challenges completed can count towards points based on what's already been done this week?
    max_completed_countable = challenges_completed_this_week.empty? ? self.user.promotion.max_challenges_completed : [self.user.promotion.max_challenges_completed, challenges_completed_this_week.size].min
    # today's completed challenges
    challenges_completed_today = self.user.challenges_received.find_by_completed_on(self.recorded_on)
    if !challenges_completed_today
      challenges_completed_today = []
    else
      challenges_completed_today = [challenges_completed_today] if !challenges_completed_today.is_a?(Array)
    end
    challenges_completed_countable = 0
    if challenges_completed_today && !challenges_completed_today.empty?
      challenges_completed_countable = (challenges_completed_today.size > max_completed_countable) ? max_completed_countable : challenges_completed_today.size
    end
    challenges_completed_points = challenges_completed_countable * self.user.promotion.challenges_completed_points

    self.challenge_points = challenges_sent_points + challenges_completed_points
    # end challenge calculations
    
  end

  def do_milestone_badges_original
    rows = connection.uncached{ connection.select_all(Badge.milestone_query(self.user_id,self.recorded_on.year)) }
    inserts = []
    updates = []
    now = self.user.promotion.current_time.to_s(:db)
    rows.each do |row|
      if row['to_do'] == 'ADD'
        inserts << "(#{self.user_id},'#{row['milestone']}',0,#{row['earned_on'].year},'#{row['earned_on']}','#{now}','#{now}')"
      elsif row['to_do'] == 'UPDATE'
        updates << [row['earned_on'],row['milestone']]
      end
    end

    deletes = (Badge::Milestones.keys - rows.collect{|row|row['milestone']}).collect{|x|"'#{x}'"}
    connection.execute "delete from badges where user_id = #{self.user_id} and earned_year = #{self.recorded_on.year} and badge_key in (#{deletes.join(",")})" unless deletes.empty?
   
    connection.execute "insert badges (user_id,badge_key,sequence,earned_year,earned_date,created_at,updated_at) values #{inserts.join(",\n")}" unless inserts.empty?

    updates.each do |array|
      connection.execute "update badges set earned_date = '#{array[0]}' where user_id = #{self.user_id} and earned_year = #{self.recorded_on.year} and badge_key = '#{array[1]}'"
    end
    
    #self.basket << self.user.badges.where(:created_at=>now)

    return true     
 
    total_points = self.user.entries.where("year(recorded_on)=#{self.recorded_on.year}").sum('daily_points+challenge_points+timed_behavior_points').to_i
    now = self.user.promotion.current_time.to_s(:db)
    today = self.user.promotion.current_date.to_s(:db)
   
    earned_badges = Hash[self.user.badges.select('distinct badge_key, earned_date').where(:earned_year=>self.recorded_on.year).all.collect{|h|[h[:badge_key],h[:earned_date]]}]
    inserts = Badge::Milestones.select{|k,v|v<=total_points && !earned_badges.keys.include?(v)}.collect{|arr| "(#{self.user_id},'#{arr[0]}',0,#{self.recorded_on.year},'#{today}','#{now}','#{now}')"}
    updates = Badge::Milestones.select{|k,v|v<=total_points && earned_badges.keys.include?(v)}.collect{|arr| "(#{self.user_id},'#{arr[0]}',0,#{self.recorded_on.year},'#{today}','#{now}','#{now}')"}
    deletes = Badge::Milestones.select{|k,v|v>total_points}.collect{|arr|"'#{arr[0]}'"}

    connection.execute "insert badges (user_id,badge_key,sequence,earned_year,earned_date,created_at,updated_at) values #{inserts.join(",\n")}" unless inserts.empty?
    connection.execute "delete from badges where user_id = #{self.user_id} and earned_year = #{self.recorded_on.year} and badge_key in (#{deletes.join(",\n")})" unless deletes.empty?

    #self.basket << self.user.badges.where(:created_at=>now)
  end

  def do_milestone_badges
    #raise caller.to_yaml
    query = Badge.milestone_query(self.user_id,self.recorded_on.year)
    return true unless query
    rows = connection.uncached{ connection.select_all(query) }
    inserts = []
    updates = []
    now = self.user.promotion.current_time.to_s(:db)
    rows.each do |row|
      if row['to_do'] == 'ADD'
        inserts << "(#{self.user_id},'#{row['milestone']}',#{row['earned_on'].year},'#{row['earned_on']}','#{now}','#{now}')"
      elsif row['to_do'] == 'UPDATE'
        updates << [row['earned_on'],row['milestone']]
      end
    end

    deletes = (self.user.promotion.milestone_goals.keys - rows.collect{|row|row['milestone']}).collect{|x|x}
    connection.execute "DELETE FROM user_badges WHERE user_id = #{self.user_id} AND earned_year = #{self.recorded_on.year} AND badge_id IN (#{deletes.join(",")})" unless deletes.empty?

    connection.execute "INSERT INTO user_badges (user_id,badge_id,earned_year,earned_date,created_at,updated_at) values #{inserts.join(",\n")}" unless inserts.empty?

    updates.each do |array|
      connection.execute "UPDATE user_badges set earned_date = '#{array[0]}' WHERE user_id = #{self.user_id} AND earned_year = #{self.recorded_on.year} AND badge_id = '#{array[1]}'"
    end

    return true

  end

  def do_weekend_badges
    return
    # the query below may help you diagnose problems with weekend badges -- look for 5 consecutive weeks in the results
    #   select week(recorded_on,1) week, min(recorded_on) from entries where user_id = 9 and weekday(recorded_on) in (5,6) group by week(recorded_on,1) order by recorded_on;

    # NOTE:  saturday,sunday is 0,6 in ruby. it is 5,6 in mysql when using mode=1 with the week argument
    if [0,6].include?(self.recorded_on.wday)
      sql = Badge.weekend_query(self.user_id,self.recorded_on.year)
      rows = connection.uncached{ connection.select_all(sql) }
      if !rows.empty?
        now = self.user.promotion.current_time.to_s(:db)
        inserts = []
        updates = []
        deletes = []
        max_sequence = -1
        rows.each do |row|
          max_sequence = [max_sequence,row['badge_key'] == Badge::WeekendWarrior ? row['sequence'] : -1].max
          inserts << "(#{self.user_id},'#{row['badge_key']}',#{row['sequence']},#{self.recorded_on.year},'#{row['recorded_on']}','#{now}','#{now}')" unless row['badge_id']
          updates << row if row['badge_id']
        end
        connection.execute "insert badges (user_id,badge_key,sequence,earned_year,earned_date,created_at,updated_at) values #{inserts.join(",\n")}" unless inserts.empty?
        updates.each do |row|
          connection.execute "update badges set earned_date = '#{row['recorded_on']}', sequence = #{row['sequence']}, updated_at = '#{now}' where id = #{row['badge_id']}"
        end
        connection.execute "delete from badges where user_id = #{self.user_id} and earned_year = #{self.recorded_on.year} and (badge_key = '#{Badge::WeekendWarrior}' and sequence > #{max_sequence})"
      else
        # no entries this year, so delete both badges.  this can happen if you delete your only entry.
        connection.execute "delete from badges where user_id = #{self.user_id} and earned_year = #{self.recorded_on.year} and badge_key in ('#{Badge::Weekender}','#{Badge::WeekendWarrior}')"
      end

      #self.basket << self.user.badges.where(:created_at=>now)
    end
  end

  def publish_to_redis
    $redis.publish('entrySaved', {:stats => self.user.stats, :user_id => self.user.id}.to_json)
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
  
end
