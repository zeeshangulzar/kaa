class Profile < ApplicationModel
  # attrs
  attr_privacy_path_to_user :user
  
  attr_accessible :gender,:first_name,:last_name,:phone,:mobile_phone,:user_id,:updated_at,:created_at, :started_on, :goal_steps, :goal_minutes, :image, :backlog_date, :default_logging_type, :employee_group, :shirt_size, :shirt_style, :ethnicity, :age, :is_reward_participant, :line1, :line2, :city, :state_province, :postal_code, :entity

  attr_privacy :first_name,:last_name,:image,:public_comment

  attr_privacy :first_name,:last_name,:phone,:mobile_phone,:user_id,:updated_at,:created_at, :started_on, :goal_steps, :goal_minutes, :backlog_date, :default_logging_type, :employee_group, :shirt_size, :shirt_style, :is_reward_participant, :line1, :line2, :city, :state_province, :postal_code, :entity, :backlog_date, :me



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
    sans_team = (self.user.promotion.backlog_days && self.user.promotion.backlog_days > 0) ? [self.user.promotion.current_date - self.user.promotion.backlog_days, self.started_on].max : self.started_on
    if !self.user.current_team
      return sans_team
    end
    return [self.user.current_team.competition.competition_starts_on, sans_team].min
  end

  def self.do_nuid_verification
    #by nuid 
    connection.execute "update users
    inner join profiles on profiles.user_id = users.id
    inner join kp_verified on kp_verified.type ='nuid' and kp_verified.value = users.altid
    set users.nuid_verified = 1
    where profiles.is_reward_participant = 1 
    and users.nuid_verified = 0
    and kp_verified.value is not null 
    and trim(kp_verified.value) <> '';"
  end


end
