# A model that handles notifications, including creating single notifications and groups of them, as well as deleting groups and marking them as seen and read.
class Notification < ApplicationModel
  belongs_to :notificationable, :polymorphic => true 
  belongs_to :user, :foreign_key => "user_id"
  belongs_to :from_user, :class_name => 'User'
  
  attr_accessible :read, :seen, :hidden, :key, :title, :message, :from_user_id, :created_at, :user_id, :link, :notificationable_type, :notificationable_id, :created_at, :updated_at, :user, :from_user
  attr_privacy :read, :seen, :hidden, :key, :title, :message, :from_user, :created_at, :link, :any_user
  attr_privacy_no_path_to_user

  #validates :title, :presence => true, :length => {:maximum => 100}
  validates :message, :presence => true
  
  scope :not_seen, where(:seen => false)
  scope :seen, where(:seen => true)
  scope :not_read, where(:read => false)
  scope :read, where(:read => true)
  scope :visible, where(:hidden => false)
  scope :hidden, where(:hidden => true)

  after_create :publish_to_redis
  before_update :set_seen

  # Deletes a group of notifications.
  def self.delete_group(notificationable, time)
    sql = "DELETE FROM `notifications` WHERE `notificationable_type` = '#{notificationable.class.to_s}' AND `notificationable_id` = #{notificationable.id} AND created_at BETWEEN '#{time.to_s(:db)}' AND '#{(time + 1.second).to_s(:db)}'"
    result = ActiveRecord::Base.connection.execute sql
  end
  
  # Creates notifications for an entire group of users.
  def self.create_for_users(notificationable, title, message, from_user, key, users)
    users.each_slice(1000).to_a.each{|user_chunk|
      sql = "INSERT INTO `notifications` (`created_at`, `updated_at`, `user_id`, `message`, `key`, `notificationable_type`, `notificationable_id` #{", `title`" unless title.to_s.empty?} #{", `from_user_id`" unless from_user.nil?}) VALUES"
      now = Time.now.to_s(:db)
      values_sql = ""
      user_chunk.each_with_index do |u,i|
        values_sql += "('#{now}', '#{now}', #{u.id}, '#{message.gsub(/\\/, '\&\&').gsub(/'/, "''")}', '#{key}', '#{notificationable.class.to_s}', #{notificationable.id} #{", '#{title.gsub(/\\/, '\&\&').gsub(/'/, "''")}'" unless title.to_s.empty?} #{", #{from_user.id}" unless from_user.nil?}),"
      end
      sql += values_sql.chop + ";"
      ActiveRecord::Base.connection.execute sql
    }
    Notification.last(:select => "COUNT(*) as total, SUM(seen) as total_seen, SUM(read) as total_read, `key`, id, title, message, created_at", :conditions => {:notificationable_type => notificationable.class.to_s, :notificationable_id => notificationable.id}, :group => "`key`")
  end
    
  # Finds all notifications matching a notificationable type and id.
  def self.find_all_by_key_group_by_created_at(notificationable)
    all(:select => "COUNT(*) as total, SUM(seen) as total_seen, SUM(read) as total_read, `key`, title, id, message, created_at, hidden, seen, read", :conditions => {:notificationable_type => notificationable.class.to_s, :notificationable_id => notificationable.id}, :group => :created_at)
  end

  # Finds all notifications matching a notificationable type and id.
  def self.find_all_group_by_key(notificationable)
    all(:select => "COUNT(*) as total, SUM(seen) as total_seen, SUM(read) as total_read, `key`, title, id, message, created_at, hidden, seen, read", :conditions => {:notificationable_type => notificationable.class.to_s, :notificationable_id => notificationable.id}, :group => '`key`', :order => 'created_at DESC')
  end

  # Marks the notification as having been seen.
  def mark_as_seen
    update_attributes(:seen => true)
  end

  # Marks the notification as having been read.
  def mark_as_read
    update_attributes(:read => true)
  end

  # Marks the notification as having been hidden.
  def mark_as_hidden
    update_attributes(:hidden => true)
  end

  # send all notifications to redis to have broadcasted via socket.io
  def publish_to_redis
    $redis.publish('notificationPublished', {:notification => self, :user_id => self.user_id}.to_json)
  end

  def set_seen
    self.seen = true if self.read
  end

end
