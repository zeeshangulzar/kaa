class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer  :user_id
      t.boolean  :viewed, :default => false
      t.text     :message
      t.string   :key, :limit => 25
      t.string   :title, :limit => 100
      t.integer  :notificationable_id
      t.string   :notificationable_type, :limit => 50
      t.integer  :from_user_id
      t.integer  :hidden, :limit => 1, :default => 0
      t.timestamps
    end
    
    add_index :notifications, :user_id
    add_index :notifications, :from_user_id
    add_index :notifications, [:notificationable_id, :notificationable_type], :name => 'notifications_index'
  end
end

