class CreateEmailReminders < ActiveRecord::Migration
  def up
    create_table :email_reminders do |t|
      t.integer   :promotion_id
      t.integer   :days
      t.string    :subject
      t.text      :body
      t.timestamps
    end

    create_table :email_reminders_sent do |t|
      t.integer   :user_id
      t.integer   :email_reminder_id
      t.timestamps
    end
  end

  def down
    remove_table :email_reminders_sent
    remove_table :email_reminders
  end
end
