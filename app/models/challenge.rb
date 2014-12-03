class Challenge < ApplicationModel
  attr_privacy :promotion_id, :name, :description, :any_user
  attr_privacy_no_path_to_user
  attr_accessible *column_names
  
  belongs_to :promotion
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  
  assigned_to_location

  has_many :challenges_sent, :class_name => "ChallengeSent"
  has_many :challenges_received, :class_name => "ChallengeReceived"

end