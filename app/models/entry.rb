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
    max_sent_countable = challenges_sent_this_week.nil? ? self.user.promotion.max_challenges_sent : [self.user.promotion.max_challenges_sent, challenges_sent_this_week.size].min
    # today's sent challenges
    challenges_sent_today = self.user.challenges_sent.where("DATE(created_at) = ?", self.recorded_on) rescue []
    challenges_sent_countable = 0
    if !challenges_sent_today.nil? && !challenges_sent_today.empty?
      challenges_sent_countable = (challenges_sent_today.size > max_sent_countable) ? max_sent_countable : challenges_sent_today.size
    end
    challenges_sent_points = challenges_sent_countable * self.user.promotion.challenges_sent_points

    # completed challenges not including today
    challenges_completed_this_week = self.user.challenges_received.where("DATE(completed_on) <> ? AND DATE(completed_on) >= ? AND DATE(completed_on) <= ?", self.recorded_on, self.recorded_on.beginning_of_week, self.recorded_on.end_of_week) rescue []
    # how many challenges completed can count towards points based on what's already been done this week?
    max_completed_countable = challenges_completed_this_week.nil? ? self.user.promotion.max_challenges_completed : [self.user.promotion.max_challenges_completed, challenges_completed_this_week.size].min
    # today's completed challenges
    challenges_completed_today = self.user.challenges_received.find_by_completed_on(self.recorded_on) rescue []
    challenges_completed_countable = 0
    if !challenges_completed_today.nil? && !challenges_completed_today.empty?
      challenges_completed_countable = (challenges_completed_today.size > max_completed_countable) ? max_completed_countable : challenges_completed_today.size
    end
    challenges_completed_points = challenges_completed_countable * self.user.promotion.challenges_completed_points

    self.challenge_points = challenges_sent_points + challenges_completed_points
    # end challenge calculations
    
  end

end