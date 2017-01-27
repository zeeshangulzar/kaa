class ChangeUrlToLinkOnNotifications < ActiveRecord::Migration
  def up
    rename_column :notifications, :url, :link
  end

  def down
    rename_column :notifications, :link, :url
  end
end
