class TeamMemberBehavior < ApplicationModel
  attr_privacy :team_member_id, :behavior_id, :recorded_on, :is_recorded, :value, :points, :me
  attr_privacy_path_to_user :team_member, :user
  attr_accessible :team_member_id, :behavior_id, :recorded_on, :is_recorded, :value, :created_at, :updated_at, :points
  
  belongs_to :team_member
  belongs_to :behavior

  validates_presence_of :team_member_id, :behavior_id

  before_create :set_default_values
  after_commit :team_member_update
  before_save :clear_value_if_empty

  # Sets the value to zero if it is an empty string
  def clear_value_if_empty
    write_attribute(:value, nil) if self.value.is_a?(String) && self.value.empty?
  end

  def set_default_values
    assign_attributes({
      :is_recorded => self.is_recorded || !self.value.nil?,
      :recorded_on => self.recorded_on ||self.team_member.user.promotion.current_date
    })
  end

  def team_member_update
    self.user.update_team_member_points()
  end

end
