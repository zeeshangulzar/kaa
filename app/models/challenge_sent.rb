class ChallengeSent < ApplicationModel
  self.table_name = "challenges_sent"

  attr_privacy_no_path_to_user
  attr_accessible *column_names
  
  belongs_to :user
  belongs_to :challenge
  belongs_to :challenged_user, :class_name => "User", :foreign_key => "to_user_id"
  belongs_to :challenged_group, :class_name => "Group", :foreign_key => "to_group_id"

  before_create :create_challenge_received

  def create_challenge_received
    receiver = User.find(self.to_user_id)
    challenge = Challenge.find(self.challenge_id)
    rcc = receiver.challenges_received.build(:status => ChallengeReceived::STATUSES['NEW'], :expires_on => receiver.promotion.current_date + 7)
    rcc.challenge = challenge
    rcc.save!
  end

end