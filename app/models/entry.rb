class Entry < ApplicationModel

  attr_accessible :recorded_on, :exercise_minutes, :exercise_steps, :is_recorded, :notes, :entry_exercise_activities, :entry_activities
  # All entries are tied to a user
  belongs_to :user

  many_to_many :with => :exercise_activity, :primary => :entry, :fields => [[:value, :integer]]

  has_many :entry_activities, :in_json => true
  accepts_nested_attributes_for :entry_activities, :entry_exercise_activities

  attr_accessible :entry_activities, :entry_exercise_activities

  attr_privacy :recorded_on, :exercise_minutes, :exercise_steps, :is_recorded, :notes, :daily_points, :challenge_points, :timed_activity_points, :updated_at, :entry_exercise_activities, :entry_activities, :me
  
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

    timed_activity_points = 0
    self.entry_activities.each do |entry_activity|
      activity = entry_activity.activity

      if entry_activity.value
        value = entry_activity.value.to_i
        value = activity.cap_value && value >= activity.cap_value ?  activity.cap_value : value

        #Timed activities override activity
        if activity.active_timed_activity
          activity.active_timed_activity.point_thresholds do |point_threshold|
            if value >= point_threshold.min
              timed_activity_points += point_threshold.value
            end #if
          end #do timed point threshold
        end #elsif
      end #if
    end #do entry_activity

    #TODO: Challenge Points Calculation

    self.timed_activity_points = timed_activity_points    
  end

end