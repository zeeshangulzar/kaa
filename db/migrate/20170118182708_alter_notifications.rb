class AlterNotifications < ActiveRecord::Migration
  def up
    rename_column :notifications, :viewed, :read
    add_column :notifications, :seen, :integer, :default => 0
  end

  def down
    rename_column :notifications, :read, :viewed
    remove_column :notifications, :seen
  end
end
