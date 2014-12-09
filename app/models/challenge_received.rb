class ChallengeReceived < ApplicationModel
  self.table_name = "challenges_received"

  attr_privacy_no_path_to_user
  attr_accessible *column_names
  
  belongs_to :user
  belongs_to :challenge

  STATUSES = {
    :pending   => 0,
    :accepted  => 1,
    :declined  => 2
  }

  before_create :set_defaults

  def set_defaults
    self.status ||= STATUSES[:pending]
    self.expires_on ||= self.challenge.promotion.current_date + 7
  end

end