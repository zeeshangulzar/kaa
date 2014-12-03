class ChallengeReceived < ApplicationModel
  self.table_name = "challenges_received"

  attr_privacy_no_path_to_user
  attr_accessible *column_names
  
  belongs_to :user
  belongs_to :challenge

  STATUSES = {
    'NEW'       => 0,
    'ACCEPTED'  => 1,
    'DECLINED'  => 2
  }

end