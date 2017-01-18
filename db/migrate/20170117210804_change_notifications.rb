class ChangeNotifications < ActiveRecord::Migration
  def up
    add_column :notifications, :url, :string
    add_column :users, :notification_count, :integer, :default => 0
  end

  def down
    remove_column :notifications, :url
    remove_column :users, :notification_count
  end
end
