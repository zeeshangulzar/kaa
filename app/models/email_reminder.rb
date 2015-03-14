# Like active record class for keeping track of likes that users have
class EmailReminder < ApplicationModel

  belongs_to :promotion
 
  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :days, :subject, :body, :master
  attr_accessible *column_names

end
