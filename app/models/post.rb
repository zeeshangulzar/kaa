# Model that is posted to walls. Can be nested or replies to other posts and also contain postable object related to post.
class Post < ActiveRecord::Base
  
  # The page size allowed for getting posts
  PAGESIZE = 10

  belongs_to :user, :in_json => true

  belongs_to :parent_post, :class_name => Post, :foreign_key => :parent_post_id

  belongs_to :root_post, :class_name => Post, :foreign_key => :root_post_id

  has_many :replies, :class_name => Post, :foreign_key => :parent_post_id, :in_json => true

  has_many :child_posts, :class_name => Post, :foreign_key => :root_post_id

  belongs_to :wallable, :polymorphic => true

  belongs_to :postable, :polymorphic => true, :in_json => true

  mount_uploader :photo, PostPhotoUploader


  # Validates post making sure attributes are present
  validates_presence_of :content, :depth, :user_id, :wallable_id, :wallable_type

  # Validates post using custom validator locatated at lib/post_validater.rb
  validates_with HesPosts::PostValidator

  attr_accessible :content, :depth, :photo, :parent_post_id, :is_flagged, :postable_type, :postable_id, :category

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

  acts_as_likeable :in_json => true

  is_postable

  scope :top, lambda { where(:depth => 0).includes([:user, {:likes => :user}, {:replies => [:user, {:likes => :user}]}] ).order("created_at DESC") }
  
  scope :reply, lambda { where("depth > 0").includes([:user, {:likes => :user}, {:replies => [:user, {:likes => :user}]}] ).order("created_at DESC") }

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
end
