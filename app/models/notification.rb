# A model that handles notifications, including creating single notifications and groups of them, as well as deleting groups and marking them as viewed.
class Notification < ApplicationModel
  belongs_to :notificationable, :polymorphic => true 
  belongs_to :user, :foreign_key => "user_id"
  belongs_to :from_user, :class_name => 'User'
  
  attr_accessible :viewed, :hidden, :key, :title, :message, :from_user, :user
  attr_privacy :viewed, :hidden, :key, :title, :message, :from_user, :user, :any_user
  attr_privacy_no_path_to_user

  validates :title, :presence => true, :length => {:maximum => 100}
  validates :message, :presence => true
  
  scope :not_viewed, where(:viewed => false)
  scope :viewed, where(:viewed => true)
  scope :visible, where(:hidden => false)
  scope :hidden, where(:hidden => true)

  after_create :publish_to_redis
  after_update :publish_to_redis

  # Deletes a group of notifications.
  def self.delete_group(notificationable, time)
    sql = "DELETE FROM `notifications` WHERE `notificationable_type` = '#{notificationable.class.to_s}' AND `notificationable_id` = #{notificationable.id} AND created_at BETWEEN '#{time.to_s(:db)}' AND '#{(time + 1.second).to_s(:db)}'"
    result = ActiveRecord::Base.connection.execute sql
  end
  
  # Creates notifications for an entire group of users.
  def self.create_for_users(notificationable, title, message, from_user, key, users)
    sql = "INSERT INTO `notifications` (`created_at`, `updated_at`, `user_id`, `message`, `key`, `notificationable_type`, `notificationable_id` #{", `title`" unless title.to_s.empty?} #{", `from_user_id`" unless from_user.nil?}) VALUES"
    now = Time.now.to_s(:db)
    values_sql = ""
    users.each_with_index do |u,i|
      values_sql += "('#{now}', '#{now}', #{u.id}, '#{message.gsub(/\\/, '\&\&').gsub(/'/, "''")}', '#{key}', '#{notificationable.class.to_s}', #{notificationable.id} #{", '#{title.gsub(/\\/, '\&\&').gsub(/'/, "''")}'" unless title.to_s.empty?} #{", #{from_user.id}" unless from_user.nil?}),"
    end
    
    sql += values_sql.chop + ";"

    ActiveRecord::Base.connection.execute sql
    
    Notification.last(:select => "COUNT(*) as total, SUM(viewed) as total_viewed, `key`, id, title, message, created_at", :conditions => {:notificationable_type => notificationable.class.to_s, :notificationable_id => notificationable.id}, :group => :created_at)
  end
  
  # Finds all notifications matching a notificationable type and id.
  def self.find_all_by_key_group_by_created_at(notificationable)
    all(:select => "COUNT(*) as total, SUM(viewed) as total_viewed, `key`, title, id, message, created_at", :conditions => {:notificationable_type => notificationable.class.to_s, :notificationable_id => notificationable.id}, :group => :created_at)
  end

  # Sets certain attributes as accessible for creating/updating
  def accessible_attributes
    attributes.delete_if {|key, value| !Notification.accessible_attributes.include?(key)}
  end

  # Marks the notification as having been viewed.
  def mark_as_viewed
    update_attributes(:viewed => true)
  end

  # Marks the notification as having been viewed.
  def mark_as_hidden
    update_attributes(:hidden => true)
  end

  def as_json(options = nil)
    hash = serializable_hash(options)
    hash.merge!('user' => user.as_json)
  end

  # send all notifications to redis to have broadcasted via socket.io
  def publish_to_redis
    $redis.publish('notificationPublished', self.to_json)
  end

end