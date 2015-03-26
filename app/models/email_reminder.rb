# Like active record class for keeping track of likes that users have
class EmailReminder < ApplicationModel

  belongs_to :promotion
 
  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :days, :subject, :body, :welcome_back_notification, :welcome_back_message, :user
  attr_accessible *column_names

  scope :asc, :order => "days ASC"
  scope :desc, :order => "days DESC"

end
