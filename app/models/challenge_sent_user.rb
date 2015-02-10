class ChallengeSentUser < ApplicationModel
  attr_privacy_no_path_to_user
  attr_accessible :challenge_sent_id, :user_id, :associated_group_id, :created_at, :updated_at
  attr_privacy :challenge_sent_id, :user_id, :associated_group_id, :created_at, :updated_at, :public
  
  belongs_to :challenged_user, :foreign_key => "user_id"
  belongs_to :challenge_sent
  belongs_to :challenged_group, :foreign_key => "associated_group_id"

end