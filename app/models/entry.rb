class Entry < ActiveRecord::Base
  include ActiveModel::Validations
  
  # All entries are tied to a user
  belongs_to :user
  
  has_many :entry_activities
  accepts_nested_attributes_for :entry_activities

  attr_accessible :recorded_on, :notes, :points, :daily_points, :challenge_points, :activity_points, :entry_activities_attributes
  
  # Can not have the same recorded on date for one user
  validates_uniqueness_of :recorded_on, :scope => :user_id
  
  # Must have the logged on date and user id
  validates_presence_of :recorded_on, :user_id

  # validates_with EntryValidator
  validate :do_validation, :on => :create
  validate :do_validation, :on => :update  
  
  # Order entries from most recently updated to least recently
  scope :recently_updated, order("`entries`.`updated_at` DESC")
  
  # Get only entries that are available for recording, can't record in the future so don't grab those entries
  scope :available, lambda{ where("`entries`.`recorded_on` <= '#{Date.today.to_s}'").order("`entries`.`recorded_on` DESC") }

  before_save :calculate_points
  
  def do_validation
    user = self.user
    if user && self.recorded_on && (self.recorded_on < user.started_on || self.recorded_on > (user.started_on + user.promotion.program_length - 1) || self.recorded_on > user.promotion.current_date)
      self.errors[:base] << "Cannot have an entry outside of user's promotion start and end date range"
    end
  end

  def calculate_points
    daily_points = 0
    timed_activity_points = 0

    # Calculate points earned for each entry activity
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
        else 
          activity.point_thresholds do |point_threshold|
            if value >= point_threshold.min
              daily_points += point_threshold.value
              break
            end #if
          end#do activity point threshold
        end#else
      end #if
    end #do entry_activity

    #TODO: Challenge Points Calculation

    self.daily_points = daily_points
    self.timed_activity_points = timed_activity_points
    
  end

end