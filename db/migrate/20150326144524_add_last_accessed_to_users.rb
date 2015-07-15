class AddLastAccessedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_accessed, :datetime
    add_column :email_reminders, :welcome_back_notification, :string
    add_column :email_reminders, :welcome_back_message, :text
  end
end
