# Like active record class for keeping track of likes that users have
class EmailRemindersSent < ApplicationModel
  self.table_name = "email_reminders_sent"

  belongs_to :user
  belongs_to :email_reminder
  attr_privacy_path_to_user :user
  attr_privacy :user_id, :user, :email_reminder_id, :email_reminder, :me
  attr_accessible :user_id, :user, :email_reminder_id, :email_reminder, :created_at, :updated_at

end
