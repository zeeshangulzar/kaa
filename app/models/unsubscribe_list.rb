class UnsubscribeList < ApplicationModel
  self.table_name = "unsubscribe_list"
  attr_accessible :promotion_id, :user_id, :email, :created_at, :updated_at
  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :user_id, :email, :public

  belongs_to :promotion
  belongs_to :user
end
