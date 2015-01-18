class Entry < ApplicationModel

  attr_accessible :recorded_on, :exercise_minutes, :exercise_steps, :is_recorded, :notes, :entry_exercise_activities, :entry_behaviors
  # All entries are tied to a user
  belongs_to :user

  many_to_many :with => :exercise_activity, :primary => :entry, :fields => [[:value, :integer]], :order => "id ASC", :allow_duplicates => true

  has_many :entry_behaviors, :in_json => true
  accepts_nested_attributes_for :entry_behaviors, :entry_exercise_activities

  attr_accessible :entry_behaviors, :entry_exercise_activities

  attr_privacy :recorded_on, :exercise_minutes, :exercise_steps, :is_recorded, :notes, :daily_points, :challenge_points, :timed_behavior_points, :updated_at, :entry_exercise_activities, :entry_behaviors, :me
  
  # Can not have the same recorded on date for one user
  validates_uniqueness_of :recorded_on, :scope => :user_id
  
  # Must have the logged on date and user id
  validates_presence_of :recorded_on, :user_id

  # validate
  validate :do_validation
  
  # Order entries from most recently updated to least recently
  scope :recently_updated, order("`entries`.`updated_at` DESC")
  
  # Get only entries that are available for recording, can't record in the future so don't grab those entries
  scope :available, lambda{ where("`entries`.`recorded_on` <= '#{Date.today.to_s}'").order("`entries`.`recorded_on` DESC") }

  before_save :calculate_points

  after_save    :do_milestone_badges
  after_destroy :do_milestone_badges
  after_save    :do_weekend_badges
  after_destroy :do_weekend_badges
  
  def do_validation
    user = self.user
    #Entries cannot be in the future, or outside of the started_on and promotion "ends on" range
    if user && self.recorded_on && (self.recorded_on < user.profile.started_on || self.recorded_on > (user.profile.started_on + user.promotion.program_length - 1) || self.recorded_on > user.promotion.current_date)
      self.errors[:base] << "Cannot have an entry outside of user's promotion start and end date range"
    end
  end

  def write_attribute_with_exercise(attr,val)
    write_attribute_without_exercise(attr,val)
    if [:exercise_minutes,:exercise_steps].include?(attr.is_a?(String) ? attr.to_sym : attr) && !self.user.nil?
      calculate_daily_points
      # set_is_recorded
    end
  end

  alias_method_chain :write_attribute,:exercise

  #Not quite sure the point of this... used to be is_logged
  def set_is_recorded
    write_attribute(:is_recorded, !exercise_minutes.to_i.zero? || !exercise_steps.to_i.zero?)
    true
  end

  def calculate_daily_points
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

    self.daily_points = points
  end #calculate_daily_points

  def calculate_points
    calculate_daily_points

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

    # sent challenges not including today
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
    challenges_completed_today = self.user.challenges_received.find_by_completed_on(self.recorded_on) rescue nil
    challenges_completed_countable = 0
    if !challenges_completed_today.nil? && !challenges_completed_today.empty?
      challenges_completed_countable = (challenges_completed_today.size > max_completed_countable) ? max_completed_countable : challenges_completed_today.size
    end
    challenges_completed_points = challenges_completed_countable * self.user.promotion.challenges_completed_points

    self.challenge_points = challenges_sent_points + challenges_completed_points
    # end challenge calculations
    
  end

  def do_milestone_badges
    rows = connection.select_all(Badge.milestone_query(self.user_id,self.recorded_on.year))
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

  def do_weekend_badges
    # the query below may help you diagnose problems with weekend badges -- look for 5 consecutive weeks in the results
    #   select week(recorded_on,1) week, min(recorded_on) from entries where user_id = 9 and weekday(recorded_on) in (5,6) group by week(recorded_on,1) order by recorded_on;

    # NOTE:  saturday,sunday is 0,6 in ruby. it is 5,6 in mysql when using mode=1 with the week argument
    if [0,6].include?(self.recorded_on.wday)
      sql = "
        select z.badge_key, week, recorded_on, z.sequence, badges.id badge_id from (
          select '#{Badge::WeekendWarrior}' badge_key, week, recorded_on, @sequence:=@sequence+1 sequence from(
              select
              @week := x.week week,
              if(@week >= @next_possible, 'Y', 'N') award,
              @next_possible:=if(@week >= @next_possible, @week+5,@next_possible) next_possible,
              x.recorded_on
              from(
                select 
                  week(entries.recorded_on,1) week,
                  min(entries.recorded_on) recorded_on, 
                  count(distinct week(moving_e.recorded_on,1)) consecutive
                from entries
                left join entries moving_e on moving_e.user_id = entries.user_id 
                                              and year(moving_e.recorded_on) = year(entries.recorded_on) 
                                              and weekday(moving_e.recorded_on) in (5,6) and week(moving_e.recorded_on,1) 
                                              between week(entries.recorded_on,1) - 4  and week(entries.recorded_on,1)
                where entries.user_id = #{self.user_id}
                and weekday(entries.recorded_on) in (5,6) 
                and year(entries.recorded_on) = #{self.recorded_on.year}
                group by week(entries.recorded_on,1)
                having count(distinct week(moving_e.recorded_on,1)) = 5
              ) x
              left join (select @next_possible := 5, @week := 1) test on 1=1
          )y 
          left join (select @sequence :=-1) test on 1=1
          where y.award = 'Y'
          UNION
          select '#{Badge::Weekender}',week(min(entries.recorded_on),1),min(entries.recorded_on),0
          from entries
          where user_id = #{self.user_id} and year(recorded_on) = #{self.recorded_on.year} and weekday(entries.recorded_on) in (5,6) 
        ) z 
        left join badges on badges.user_id = #{self.user_id} and earned_year = #{self.recorded_on.year} and badges.badge_key = z.badge_key and badges.sequence = z.sequence"

      rows = connection.select_all(sql)
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
  
end
