class Competition < ApplicationModel
  
  # Associations
  belongs_to :promotion
  
  has_many :teams, :order => "name ASC"
  has_many :official_teams, :class_name => "Team", :conditions => {:status => Team::Status[:official]}, :order => "name ASC"
  has_many :pending_teams, :class_name => "Team", :conditions => {:status => Team::Status[:pending]}, :order => "name ASC"
  has_many :invites, :source => :team_memberships, :through => :teams, :order => "teams.name"
  has_many :competitors, :source => :team_memberships, :through => :teams, :conditions => "teams.status = #{Team::Status[:official]} AND team_memberships.status = #{TeamMembership::Status[:accepted]}"


  maintain_sequence :scope=>:promotion_id, :order=>:competition_starts_on
  
  default_value_for :team_size_min, 4
  default_value_for :team_size_max, nil
  
  def during_enrollment?(dte=promotion.current_date)
    dte.between?(enrollment_starts_on,enrollment_ends_on)
  end

  def during_competition?(dte=promotion.current_date)
    dte.between?(competition_starts_on,competition_ends_on)
  end

  def after_competition?(dte=promotion.current_date)
    dte > competition_ends_on
  end

  def competition_ends_on
    competition_ends_at.to_date #always return as a date
  end
  
  def competition_ends_at 
    #this method does not return a Time object
    ends_on = competition_starts_on + length_of_competition - 1
    ends_on += 0.hours # not really necessary, but this allows us to include the time and follows the 5on5 pattern (e.g. add 48 hours to extend Friday end dates, etc)
    ends_on
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
end
