# Friendship active record class for keeping track of relationships between users
class Friendship < ApplicationModel
  attr_accessible :friendee, :friender, :friender_id, :friender_type, :friendee_id, :friendee_type, :status, :friend_email

  attr_privacy :friender_id, :friender_type, :friendee_id, :friendee_type, :status, :friend_email, :me
  attr_privacy_path_to_user :friender
  
  attr_accessor :is_inverse
  attr_writer :url
  
  # Constant for keeping statuses only one character in database
  STATUS = {
    :pending => 'P',
    :requested => 'R',
    :accepted => 'A',
    :declined => 'D'
  }

  # belongs_to :user, :in_json => true 
  # belongs_to :friend, :class_name => 'User', :in_json => true

  # Any ActiveRecord model can be friendable and have friends

  # The user that has been friended
  belongs_to :friendee, :polymorphic => true, :in_json => true

  # The user that owns this relationship
  belongs_to :friender, :polymorphic => true, :in_json => true

  # The user that ACTUALLY OWNS this relationship, when you create an inverse friendship
  # the friendee becomes the friender, in which case we don't know who sent the invite
  # and we need to know this so the friender can't update the status and accept the friendship their self
  belongs_to :sender, :polymorphic => true
  
  # Creates scopes for limit friendships to specific status
  # @return [ActiveRecord::Relation] scoped to the status
  # @example
  #  Friendship.pending
  #  @target_user.friendships.accepted
  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end

  # Creates methods to test which status the friendship currently is
  # @return [Boolean] true if status is matching, false otherwise
  # @example
  #  @friendship.accepted?
  #  @target_user.friendships.first.pending?
  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  # Scope for friendships that are still pending or requested
  self.send(:scope, :not_accepted, where(["`#{self.table_name}`.`status` IN (:statuses)", {:statuses => [STATUS[:pending], STATUS[:requested]]} ]))
  
  # @!group Validators
  # Makes sure there are only unique friendship relationships
  validates_uniqueness_of :friender_id, :scope => [:friendee_id, :friendee_type, :friender_type]
  # validates_uniqueness_of :user_id, :scope => :friend_id
  # validates_presence_of :friend_id, :if => Proc.new {|friendship| friendship.accepted? }
  validates_presence_of :friendee_id, :if => Proc.new {|friendship| friendship.accepted? }

  validates_presence_of :friendee_type

  validate :friendee_id_or_friend_email
  # friendee_id or email is compulsory
  def friendee_id_or_friend_email
    if self.friendee_id.blank? && self.friend_email.blank?
      errors.add(:base, "Either friendee id or friend email required.")
      return false
    end
  end

  validate :friender_not_friendee
  # your only friends are make believe
  def friender_not_friendee
    if self.friendee_id == self.friender_id
      errors.add(:base, "Can't be friends with self.")
      return false
    end
  end

  validate :friendee_exists
  # your only friends are make believe
  def friendee_exists
    if !self.friendee_id.blank?
      if !User.exists?(self.friendee_id)
        errors.add(:base, "Friendee doesn't exist.")
        return false
      end
    end
  end

  validate :status_in_statuses
  # don't set status to whatever...
  def status_in_statuses
    if !STATUS.values.include?(self.status)
      errors.add(:base, "Invalid status.")
      return false
    end
  end
  # !@endgroup
  
  # @!group Callbacks
  after_initialize :fix_types
  before_create :fix_types
  before_create :set_sender
  # Creates an inverse relationship
  after_create :create_inverse_friendship, :if => Proc.new {|friendship| !friendee_id.nil?} if HesFriendships.create_inverse_friendships
  
  # Updates inverse relationship to also be accepted
  after_update :accept_inverse_friendship, :if => Proc.new {|friendship| friendship.status_was == STATUS[:pending] && friendship.status == STATUS[:accepted]}
  
  # Destroy inverse friendship if it exists
  after_destroy :destroy_inverse_friendship, :if => Proc.new {|friendship| !friendship.inverse_friendship.nil?}
  # @!endgroup

  def fix_types
    self.friender_type = self.friender_type.blank? ? 'User' : self.friender_type.camelize
    self.friendee_type = self.friendee_type.blank? ? 'User' : self.friendee_type.camelize
  end

  def set_sender
    self.sender_type ||= 'User'
    if is_inverse
      self.sender_id ||= self.friendee_id
    else
      self.sender_id ||= self.friender_id
    end
  end
  
  # Creates an inverse friendship
  # @return [Boolean] true if inverse friendship was created successfully
  def create_inverse_friendship
    unless is_inverse
      inverse_friendship = friendee.friendships.build(:friendee => friender, :friender => friendee, :status => accepted? ? STATUS[:accepted] : STATUS[:pending])
      inverse_friendship.is_inverse = true
      inverse_friendship.save
    end
  end
  
  # Accepts inverse friendship
  # @return [Boolean] true if inverse friendship is accepted successfully
  def accept_inverse_friendship
    inverse_friendship.accept if !inverse_friendship.nil?
  end
  
  # Destroys the inverse friendship
  def destroy_inverse_friendship
    inverse_friendship.destroy if !inverse_friendship.nil?
  end
  
  # Accepts a friendship request by updating status to accepted
  # @return [Boolean] true if friendship was succesfully accepted, false if there was an error
  def accept
    update_attributes(:status => STATUS[:accepted])
  end

  # Checks to see if the friend associated to this friendship exists in the database
  # @return [Boolean] true if friend is registered, false if not
  def friend_exists?
    return !friendee_id.nil?
  end

  # Gets the label of the current status of this friendship
  # @return [String] of the friendly status
  def status_label
    STATUS.keys[STATUS.values.index(status)].to_s
  end
  
  # Gets the inverse friendship
  # @return [Friendship] that is related to the friend of this friendship
  def inverse_friendship
    @inverse_friendship ||= Friendship.where({:friendee_id => friender_id, :friendee_type => friender_type, :friender_id => friendee_id, :friender_type => friendee_type}).first
  end
  
  # Sets the inverse friendship
  # @param [Friendship] friendship that is related to the friend of this friendship
  def inverse_friendship=(friendship)
    @inverse_friendship = friendship
  end
  
  # List attributes that are accessible. Useful for figuring out what can be posted to server.
  # @return [Hash] attributes that can be mass updated.
  def accessible_attributes
    attributes.delete_if {|key, value| !Friendship.accessible_attributes.include?(key) }
  end
end
