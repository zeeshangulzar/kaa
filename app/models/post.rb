# Model that is posted to walls. Can be nested or replies to other posts and also contain postable object related to post.
class Post < ApplicationModel

  attr_privacy :content, :depth, :photo, :parent_post_id, :root_post_id, :is_flagged, :postable_type, :postable_id, :wallable_id, :wallable_type, :created_at, :updated_at, :flagged_by, :user, :title, :replies, :likes, :views, :any_user
  
  # The page size allowed for getting posts
  PAGESIZE = 20

  belongs_to :user

  belongs_to :parent_post, :class_name => Post, :foreign_key => :parent_post_id

  belongs_to :root_post, :class_name => Post, :foreign_key => :root_post_id

  has_many :replies, :class_name => Post, :foreign_key => :parent_post_id, :order => "created_at DESC"

  has_many :child_posts, :class_name => Post, :foreign_key => :root_post_id

  belongs_to :wallable, :polymorphic => true

  belongs_to :postable, :polymorphic => true

  mount_uploader :photo, PostPhotoUploader

  # Validates post making sure attributes are present
  validates_presence_of :content, :depth, :user_id, :wallable_id, :wallable_type

  # Validates post using custom validator locatated at lib/post_validater.rb
  validates_with HesPosts::PostValidator

  attr_accessible *column_names

  # Set the root post id before validation
  before_validation :set_root_post_id

  # Set the wallable object before validation
  before_validation :set_wallable

  # Fired after post is replied to
  event_accessor :after_reply
  after_create lambda { |post| post.parent_post.fire_after_reply(post) }, :if => lambda { |post| post.reply? }

  # Fired after a reply is destroyed
  event_accessor :after_reply_destroyed
  after_destroy lambda { |post| post.parent_post.fire_after_reply_destroyed(post) }, :if => lambda { |post| post.reply? && post.parent_post }

  acts_as_likeable

  is_postable

  acts_as_notifier

  after_update :notify_if_flagged

  scope :top, lambda { where(:depth => 0).includes([:user, {:likes => :user}, {:replies => [:user, {:likes => :user}]}] ).order("posts.created_at DESC") }

  scope :locationed, lambda { |location_id|
    locations = Location.find(location_id).children.collect{|l|l.id}.push(location_id)
    where(:depth => 0, :users => {:location_id => locations}).includes([:user, {:likes => :user}, {:replies => [:user, {:likes => :user}]}] ).order("posts.created_at DESC")
  }
  
  scope :reply, lambda { where("depth > 0").includes([:user, {:likes => :user}, {:replies => [:user, {:likes => :user}]}] ).order("posts.created_at DESC") }

  scope :before, lambda { |post_id| where("`posts`.id < :post_id", {:post_id => post_id || 10000000}) }

  scope :after, lambda { |post_id| where("`posts`.id > :post_id", {:post_id => post_id || -1}) }

  scope :from_users, lambda { |user_ids| where("`posts`.user_id in (:uids)", {:uids => user_ids}) }

  # Gets the key to be applied to the formula for popular weight based on created_at
  def days_old_weight
    difference = Date.today - self.created_at.to_date
    HesPosts.days_old_weight.keys.sort{|x,y| y <=> x}.each do |day|  
      return HesPosts.days_old_weight[day] if difference >= day
    end
    return 1
  end

  # The root id should be set before a post is created. It should be either the parent id or the parent's root_post_id.
  # @return [Boolean] true
  def set_root_post_id
    unless depth.zero? || self.root_post_id
      self.root_post_id = self.parent_post.depth.zero? ? self.parent_post_id : self.parent_post.root_post_id unless self.parent_post.nil?
    end

    true
  end

  # The wallable id and type should be set before the post is created. It should be the same as the parent wallable id and type.
  # @return [Boolean] true
  def set_wallable
    unless depth.zero? || (self.wallable_type && self.wallable_id)
      self.wallable_id = self.parent_post.wallable_id
      self.wallable_type = self.parent_post.wallable_type
    end

    true
  end

  # Returns whether or not post is a reply
  # @return [Boolean] true if is a reply (depth greater than 0), false if root post (depth is 0)
  def reply?
    return !depth.zero?
  end

  # Creates this post on the wallable passed in. Used for chaining.
  # @param [Wallable] wallable that this post is being added to
  # @return [Post] post that has been added to wallable
  # @example
  #  @user.post("I'm doing my laundry").to(@promotion)
  #  @user.post("I'm eating this recipe", @recipe).to(@promotion)
  def to(wallable)
    self.wallable = wallable
    save
    self
  end

  # Override postable so that ActiveResource polymorphic association works
  # @todo Need to write a test to make sure ActiveResource models work
  def postable(*args)
    if self.postable_type.nil? || self.postable_type.constantize < ActiveRecord::Base
      super
    elsif self.postable_type.constantize < ActiveResource::Base
      self.postable_type.constantize.send(:find, self.postable_id)
    end
  rescue
    super
  end




    # Like actions
  after_like :create_post_owner_notification_of_like
  after_unlike :destroy_post_owner_notification_of_like
  # Reply actions
  after_reply :create_post_owner_notification_of_reply
  after_reply_destroyed :destroy_post_owner_notification_of_reply

  # Creates a notification after a post is liked
  # @param [Like] like that was generated from liking this post
  # @return [Notification] notification that was generated after liking post
  # @note Notification title and message can be edited in hes-posts_config file in config/initializers folder.
  def create_post_owner_notification_of_like(like)
    return if like.user.id == self.user.id # don't notify user of his own likes..
    unless self.user.role == "Poster"
      notify(self.user, "Your post was liked!", "#{like.user.profile.full_name} liked your <a href='/#/wellness_wall/#{self.id}'>post</a>!", :from => like.user, :key => post_like_notification_key(like))
    else
      self.postable.notify(self.user, HesPosts.post_liked_notification_title.call(self.postable, like), HesPosts.expert_post_liked_notification_message.call(self.postable, like), :from_user => like.user, :key => post_like_notification_key(like))
    end
  end

  # Creates a notification after a post is liked
  # @param [Like] like that was generated from liking this post
  # @return [Boolean] true if notification was destroyed, false if it was not
  def destroy_post_owner_notification_of_like(like)
    unless self.user.role == "Poster"
      self.notifications.find_by_key(post_like_notification_key(like)).destroy rescue true
    else
      self.postable.notifications.find_by_key(post_like_notification_key(like)).destroy rescue true
    end
  end

  # The key that is generated to find likes tied to a notification
  # @param [Like] like used for notification key
  # @return [String] key that will be used to create notification
  def post_like_notification_key(like)
    "post_like_#{like.id}"
  end


  # Creates a notification after a post is replied to
  # @param [Post] reply post
  # @return [Notification] notification that was generated after replying to post
  # @note Notification title and message can be edited in hes-posts_config file in config/initializers folder.
  def create_post_owner_notification_of_reply(reply)
    return if reply.user.id == self.user.id # don't notify user of his own replies..
    unless self.user.role == "Poster"
      notify(self.user, "Your post was replied to!", "#{reply.user.profile.full_name} replied to your <a href='/#/wellness_wall/#{self.id}?reply=#{reply.id}'>post</a>!", :from => reply.user, :key => post_reply_notification_key(reply))
    else
      self.postable.notify(self.postable.user, HesPosts.post_replied_notification_title.call(self.postable, reply), HesPosts.expert_post_replied_notification_message.call(self.postable, reply), :from_user => reply.user, :key => post_reply_notification_key(reply))
    end
  end

  # Destroys the notification after a post reply is destroyed
  # @return [Boolean] true if notification was destroyed, false if it was not
  def destroy_post_owner_notification_of_reply(reply)
    unless self.user.role == "Poster"
      self.notifications.find_by_key(post_reply_notification_key(reply)).destroy rescue true
    else
      self.postable.notifications.find_by_key(post_reply_notification_key(reply)).destroy rescue true
    end
  end

  # The key that is generated to find replies tied to a notification
  # @param [Post] reply used for notification key
  # @return [String] key that will be used to create notification
  def post_reply_notification_key(reply)
    "post_reply_#{reply.id}"
  end


  # badges...

  after_create :do_badges
  after_destroy :do_badges

  def do_badges
    return Badge.do_enthusiast(self)
  end

  def root_user
    return !self.root_post.nil? ? self.root_post.user : self.user
  end

  def as_json(options={})
    if !options[:methods].nil? && (options[:methods] == 'root_user' || options[:methods].include?('root_user'))
      options = options.merge({:methods => ["root_user"]})
    end
    super
  end

  def notify_if_flagged
    if !self.is_flagged_was && self.is_flagged
      notify(self.user, "Your post has been flagged.", "Your <a href='/#/wellness_wall/#{self.id}'>post</a> was flagged.", :from => self.user, :key => "post_" + self.id.to_s)
    end
  end



  # big ass method to get everything on the wall without active record junk
  # it's ugly, but it's fast...
  def self.wall(wall, conditions = {}, count = false)
    conditions = {
      :offset       => 0,
      :limit        => 50,
      :user_ids     => [],
      :location_ids => [],
      :has_photo    => nil,
      :current_year => Date.today.year
    }.merge(conditions)

    if count
      # handle count of top posts separately as we don't want to use ActiveRecord's yucky count method
      posts_sql = "
        SELECT
        COUNT(posts.id) AS count
        FROM
        posts
      "
      if !conditions[:location_ids].empty? || !conditions[:user_ids].empty?
        posts_sql = posts_sql + " JOIN users ON users.id = posts.user_id "
        posts_sql = posts_sql + " AND ( users.location_id IN (#{conditions[:location_ids].join(',')}) OR users.top_level_location_id IN (#{conditions[:location_ids].join(',')}) )" if !conditions[:location_ids].empty?
        posts_sql = posts_sql + " AND users.id IN (#{conditions[:user_ids].join(',')}) " if !conditions[:user_ids].empty?
      end
      posts_sql = posts_sql + "
        WHERE
        parent_post_id IS NULL AND wallable_id = #{wall.id}
        #{ 'AND posts.photo IS NOT NULL' if conditions[:has_photo] }
        ORDER BY posts.created_at DESC
      "
      result = self.connection.exec_query(posts_sql)
      return result.first['count'].to_s
    end


    posts_sql = "
      SELECT
      posts.id, posts.content, posts.photo, posts.is_flagged, posts.created_at, posts.user_id
      FROM
      posts
    "
    if !conditions[:location_ids].empty? || !conditions[:user_ids].empty?
      posts_sql = posts_sql + " JOIN users ON users.id = posts.user_id "
      posts_sql = posts_sql + " AND ( users.location_id IN (#{conditions[:location_ids].join(',')}) OR users.top_level_location_id IN (#{conditions[:location_ids].join(',')}) )" if !conditions[:location_ids].empty?
      posts_sql = posts_sql + " AND users.id IN (#{conditions[:user_ids].join(',')}) " if !conditions[:user_ids].empty?
    end
    posts_sql = posts_sql + "
      WHERE
      parent_post_id IS NULL AND wallable_id = #{wall.id}
      #{ 'AND posts.photo IS NOT NULL' if conditions[:has_photo] }
      ORDER BY posts.created_at DESC
      LIMIT #{conditions[:offset]}, #{conditions[:limit]}
    "

    result = self.connection.exec_query(posts_sql)
    posts = []
    result.each{|row|
      post = {}
      post['id']         = row['id']
      post['content']    = row['content']
      post['photo']      = row['photo'].nil? ? PostPhotoUploader::default_url : PostPhotoUploader::asset_host_url + row['photo'].to_s
      post['is_flagged'] = row['is_flagged']
      post['flagged_by'] = row['flagged_by']
      post['created_at'] = row['created_at']
      post['user_id']    = row['user_id']
      posts << post
    }

    return [] if posts.empty?

    replies_sql = "
      SELECT
      posts.id, posts.content, posts.photo, posts.is_flagged, posts.created_at, posts.user_id, posts.parent_post_id
      FROM
      posts
      WHERE
      parent_post_id IN (#{posts.collect{|p|p['id']}.join(',')})
      ORDER BY created_at ASC
    "
    result = self.connection.exec_query(replies_sql)
    replies = []
    result.each{|row|
      reply = {}
      reply['id']             = row['id']
      reply['content']        = row['content']
      reply['photo']          = row['photo'].nil? ? PostPhotoUploader::default_url : PostPhotoUploader::asset_host_url + row['photo'].to_s
      reply['is_flagged']     = row['is_flagged']
      reply['flagged_by']     = row['flagged_by']
      reply['created_at']     = row['created_at']
      reply['user_id']        = row['user_id']
      reply['parent_post_id'] = row['parent_post_id']
      replies << reply
    }

    likes_sql = "
      SELECT
      likes.id, likes.user_id, likes.likeable_id
      FROM likes
      WHERE
      likeable_type = 'Post' AND likeable_id IN (#{(posts.collect{|p|p['id']} + replies.collect{|r|r['id']}).join(',')})
    "

    result = self.connection.exec_query(likes_sql)

    likes = []

    result.each{|row|
      like = {}
      like['id']          = row['id']
      like['user_id']     = row['user_id']
      like['likeable_id'] = row['likeable_id']
      likes << like
    }

    users = []

    users_sql = "
      SELECT
      users.id AS user_id, profiles.id AS profile_id, profiles.first_name, profiles.last_name, profiles.image,
      user_badge.id AS milestone_id, locations.id AS location_id, locations.name AS location_name
      FROM users
      JOIN profiles ON profiles.user_id = users.id
      JOIN locations ON locations.id = users.top_level_location_id
      LEFT JOIN (
        SELECT
        user_badges.user_id, badges.id
        FROM user_badges
        JOIN badges ON badges.id = user_badges.badge_id
        JOIN (
          SELECT
          user_id, MAX(point_goal) as point_goal
          FROM
          user_badges
          JOIN badges ON badges.id = user_badges.badge_id
          WHERE
          badges.badge_type = 'milestone'
          AND user_badges.earned_year = #{conditions[:current_year]}
          GROUP BY user_id
        ) max_badge ON max_badge.user_id = user_badges.user_id AND max_badge.point_goal = badges.point_goal
      ) user_badge ON user_badge.user_id = users.id
      WHERE users.id IN (#{( posts.collect{|p|p['user_id']} + replies.collect{|r|r['user_id']} + likes.collect{|l|l['user_id']} ).join(',')})
    "

    result = self.connection.exec_query(users_sql)

    users = []
    users_idx = {}

    result.each{|row|
      user = {}
      user['id']                      = row['user_id']
      user['profile']                 = {}
      user['profile']['image']        = {}
      user['location']                = {}
      user['profile']['id']           = row['profile_id']
      user['profile']['first_name']   = row['first_name']
      user['profile']['last_name']    = row['last_name']
      user['profile']['image']['url'] = row['image'].nil? ? ProfilePhotoUploader::default_url : ProfilePhotoUploader::asset_host_url + row['image'].to_s
      user['milestone_id']            = row['milestone_id']
      user['location_id']             = row['location_id']
      user['location']['id']          = row['location_id']
      user['location']['name']        = row['location_name']

      users_idx[row['user_id']] = user

      users << user
    }

    
    likes.each_with_index{|like, index|
      likes[index]['user'] = users_idx[like['user_id']]
    }


    replies.each_with_index{|reply, index|
      replies[index]['user'] = users_idx[reply['user_id']]
      replies[index]['likes'] = likes.select{|like|like['likeable_id'] == reply['id']}
    }

    posts.each_with_index{|post, index|
      posts[index]['user'] = users_idx[post['user_id']]
      posts[index]['posts'] = replies.select{|reply|reply['parent_post_id'] == post['id']}
    }

    return posts

  end

end
