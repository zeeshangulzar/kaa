class UserEmailOptions < ActiveRecord::Migration
  def up
    add_column :users, :allows_daily_email, :boolean, :default => true
    add_column :users, :allows_daily_email_monday_only, :boolean, :default => false
    puts "Total Users: #{User.all.count}"
    i = 0
    User.all.each{|u|
      i += 1
      update = u.update_attributes(:allows_daily_email => u.flags[:allow_daily_emails_all_week], :allows_daily_email_monday_only => u.flags[:allow_daily_emails_monday]) rescue nil
      puts i.to_s 
    }
  end
  def down
    remove_column :users, :allows_daily_email
    remove_column :users, :allows_daily_email_monday_only
  end
end
