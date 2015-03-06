class FitbitViews < ActiveRecord::Migration
  def self.up
    execute "create view device_apps AS select * from fbskeleton.apps"
    execute "create view fitbit_notifications as select * from fbskeleton.fitbit_notifications_view"
    execute "create view fitbit_notification_batches as select * from fbskeleton.fitbit_notification_batches_view"
    execute "create view fitbit_user_daily_activities as select * from fbskeleton.fitbit_user_daily_activities_view"
    execute "create view fitbit_user_daily_goals as select * from fbskeleton.fitbit_user_daily_goals_view"
    execute "create view fitbit_user_daily_summaries as select * from fbskeleton.fitbit_user_daily_summaries_view"
    execute "create view fitbit_user_daily_summary_distances as select * from fbskeleton.fitbit_user_daily_summary_distances_view"
    execute "create view fitbit_users as select * from fbskeleton.fitbit_users_view"
    execute "create view fitbit_oauth_tokens as select * from fbskeleton.fitbit_oauth_tokens_view"
  end

  def self.down
  end
end
