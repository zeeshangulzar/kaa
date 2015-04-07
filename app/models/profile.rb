class Profile < ApplicationModel
  # attrs
  attr_accessible :gender,:first_name,:last_name,:phone,:mobile_phone,:user_id,:updated_at,:created_at, :started_on, :goal_steps, :goal_minutes, :image, :backlog_date, :default_logging_type, :employee_group, :shirt_size, :shirt_style, :ethnicity, :age, :is_reward_participant, :entity
  attr_privacy :first_name,:last_name,:phone,:mobile_phone,:user_id,:updated_at,:created_at, :started_on, :goal_steps, :goal_minutes, :backlog_date, :default_logging_type, :employee_group, :shirt_size, :shirt_style, :is_reward_participant, :entity, :me
  attr_privacy :first_name,:last_name,:image,:public_comment
  attr_privacy_path_to_user :user

  # validation
  validates_presence_of :first_name, :last_name

  # relationships
  belongs_to :user

  mount_uploader :image, ProfilePhotoUploader

  # includes
  include TrackChangedFields
  # udfable is breaking things..
  # none of the methods below were defined with udfable "enabled" (not commented out)
  # udfable

  # flags
  flags :has_changed_password_at_least_once, :default => false

  # hooks
  before_create :set_default_values

  # constants
  GoalMin = 150
  GoalMax = 360
  Gender = [['-- Choose --', ''], ['Female','F'], ['Male','M'] ]
  DaysActivePerWeek = [['-- Choose --', ''], [0,0],[1,1],[2,2],[3,3],[4,4],[5,5],[6,6],[7,7] ]
  MinutesPerDay = [['-- Choose --', ''], ['0 - 15', '0 - 15'], ['16 - 30', '16 - 30'], ['31 - 45','31 - 45'], ['46 - 60','46 - 60'], ['More than 60', 'More than 60'] ]

  # methods

  # Full name (if both first and last name are present)
  def full_name
    first_name.to_s + " " + last_name.to_s
  end

  # Email with full name returned or nil
  def email_with_name
    "#{full_name} <#{email.to_s}>"
  end
  
  def email_with_name_escaped
    email_with_name.gsub("<", "&lt;").gsub(">", "&gt;")
  end

  def self.get_next_start_date(promotion,today=Date.today)
    return today if promotion.nil?
    if promotion.starts_on && promotion.registration_starts_on && promotion.registration_ends_on && promotion.registration_starts_on <= today && today <= promotion.registration_ends_on
      return promotion.starts_on
    elsif promotion.starts_on && today <= promotion.starts_on
      return promotion.starts_on
    else
      return today
    end
  end

  def set_default_values
    promotion = self.user.promotion
    self.registered_on = promotion.current_date
    self.started_on = self.class.get_next_start_date(promotion)
  end

  def backlog_date
    # TODO: delete me after pilot
    # pilot-specific hard-coded backlog date
    if self.user.promotion.subdomain == "pilot"
      if self.started_on < "2015-03-16".to_date
        return "2015-03-13".to_date
      else
        return "2015-03-16".to_date
      end
    end
    return (self.user.promotion.backlog_days && self.user.promotion.backlog_days > 0) ? [self.user.promotion.current_date - self.user.promotion.backlog_days, self.started_on].max : self.started_on
  end

  def as_json(options={})
    options = options.merge({:methods => ["backlog_date"]})
    super
  end

end
