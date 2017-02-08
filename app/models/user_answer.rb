class UserAnswer < ApplicationModel
  attr_accessible :user_id, :destination_id, :answer, :is_correct, :created_at, :updated_at
  attr_privacy :user_id, :destination_id, :answer, :is_correct, :created_at, :updated_at, :any_user
  
  belongs_to :user
  belongs_to :destination

end
