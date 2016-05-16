class Friendship < ApplicationModel

  attr_accessible :friendee, :friender, :friender_id, :friendee_id, :status, :friend_email, :sender_id, :message
  attr_privacy :friender_id, :friendee_id, :friendee, :status, :friend_email, :sender_id, :me
  attr_privacy_path_to_user :friender
  attr_accessor :is_inverse

  Label = "Buddy"
  
  # Constant for keeping statuses only one character in database
  STATUS = {
    :pending => 'P',
    :requested => 'R',
    :accepted => 'A',
    :declined => 'D'
  }

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

  # The user that has been friended
  belongs_to :friendee, :class_name => "User"

  # The user that owns this relationship
  belongs_to :friender, :class_name => "User"

  # The user that ACTUALLY OWNS this relationship, when you create an inverse friendship
  # the friendee becomes the friender, in which case we don't know who sent the invite
  # and we need to know this so the friender can't update the status and accept the friendship their self
  belongs_to :sender, :class_name => "User"

  acts_as_notifier
  after_create :send_requested_notification
  after_update :send_accepted_notification
  after_update :mark_notification_as_viewed

  before_create :set_sender
  # Creates an inverse relationship
  after_create :create_inverse_friendship, :if => Proc.new {|friendship| !friendee_id.nil?}
  before_update :update_sender
  after_update :set_inverse_friendship
  
  # Updates inverse relationship to also be accepted
  after_update :accept_inverse_friendship, :if => Proc.new {|friendship| friendship.status_was == STATUS[:pending] && friendship.status == STATUS[:accepted]}
  after_update :decline_inverse_friendship, :if => Proc.new {|friendship| friendship.status_was == STATUS[:pending] && friendship.status == STATUS[:declined]}
  after_update :set_pending_inverse_friendship, :if => Proc.new {|friendship| friendship.status_was == STATUS[:declined] && friendship.status == STATUS[:pending]}

  # Sends notification to the user that friendship was requested of
  # @note Sent after friendships is created
  def send_requested_notification
    unless status == Friendship::STATUS[:accepted] || is_inverse
      if !friendee.nil?
        notify(friendee, "#{Label} Request", "#{friender.profile.full_name} has requested to be your <a href='/#/#{Friendship::Label.pluralize.downcase}'>#{Friendship::Label}</a>.", :from => friender, :key => "friendship_#{id}")
        if friendee.flags[:notify_email_friend_requests]
          Resque.enqueue(FriendInviteEmail, friendee.id, friender.id)
        end
      else
      end
    else
      Resque.enqueue(InviteEmail, [self.friend_email], self.sender_id, self.message)
    end
  end

  # Sends notification if friendships is updated with a friend id
  # @note Called after friendships is updated
  # @see #send_notification
  def send_accepted_notification
    if self.status == Friendship::STATUS[:pending] && self.status_was == Friendship::STATUS[:declined] && !is_inverse
      self.send_requested_notification
    elsif !self.friendee.nil? && !self.friender.nil? && self.status == Friendship::STATUS[:accepted] && self.status_was != Friendship::STATUS[:accepted] && !is_inverse
      receiver = (self.sender_id == self.friender_id) ? self.friender : self.friendee
      remitter = (self.sender_id == self.friender_id) ? self.friendee : self.friender
      notify(receiver, "#{Label} Accepted", "#{remitter.profile.full_name} has accepted your <a href='/#/#{Friendship::Label.pluralize.downcase}'>#{Friendship::Label}</a> request.", :from => remitter, :key => "friendship_#{id}")
      if receiver.flags[:notify_email_friend_requests]
        # TODO: resque email friend request notification
      end
    end
  end

  # marks notification as read after friendships has been accepted or declined
  def mark_notification_as_viewed
    notifications.each{|n| n.update_attributes(:viewed => true)} if (status == Friendship::STATUS[:accepted] || status == Friendship::STATUS[:declined]) && status_was == Friendship::STATUS[:pending]
  end
  

  # Makes sure there are only unique friendship relationships
  validates_uniqueness_of :friendee_id, :scope => [:friender_id], :if => Proc.new{|friendship| !friendship.friendee_id.nil? }
  validates_uniqueness_of :friend_email, :scope => [:friender_id], :if => Proc.new{|friendship| !friendship.friend_email.nil? }
  validates_presence_of :friendee_id, :if => Proc.new {|friendship| friendship.accepted? }
  validate :friendee_id_or_friend_email
  validate :friender_not_friendee
  validate :friendee_exists
  validate :status_in_statuses

  # friendee_id or email is compulsory
  def friendee_id_or_friend_email
    if self.friendee_id.blank? && self.friend_email.blank?
      errors.add(:base, "Either friendee id or friend email required.")
      return false
    end
  end

  # your only friends are make believe
  def friender_not_friendee
    if self.friendee_id == self.friender_id
      errors.add(:base, "Can't be friends with self.")
      return false
    end
  end

  # your only friends are make believe
  def friendee_exists
    if !self.friendee_id.blank?
      if !User.exists?(self.friendee_id)
        errors.add(:base, "Friendee doesn't exist.")
        return false
      end
    end
  end

  # don't set status to whatever...
  def status_in_statuses
    if !STATUS.values.include?(self.status)
      errors.add(:base, "Invalid status.")
      return false
    end
  end
  
  def set_sender
    if is_inverse
      Rails.logger.warn(self.id.to_s + ' is inverse')
      self.sender_id = self.friendee_id
    else
      Rails.logger.warn(self.id.to_s + ' is NOT inverse')
      self.sender_id = self.friender_id
    end
  end

  def update_sender
    if self.status_was == STATUS[:declined] && self.status == STATUS[:pending]
      Rails.logger.warn("set sender: " + self.id.to_s)
      self.set_sender
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

  # Creates an inverse friendship
  # @return [Boolean] true if inverse friendship was created successfully
  def set_inverse_friendship
    unless is_inverse
      inverse_friendship = self.inverse_friendship
      inverse_friendship.is_inverse = true
    end
  end
  
  # Accepts inverse friendship
  # @return [Boolean] true if inverse friendship is accepted successfully
  def accept_inverse_friendship
    inverse_friendship.accept if !inverse_friendship.nil?
  end

  # Accepts inverse friendship
  # @return [Boolean] true if inverse friendship is accepted successfully
  def decline_inverse_friendship
    inverse_friendship.decline if !inverse_friendship.nil?
  end

  # Accepts inverse friendship
  # @return [Boolean] true if inverse friendship is accepted successfully
  def set_pending_inverse_friendship
    inverse_friendship.set_pending if !inverse_friendship.nil?
  end
  
  # Accepts a friendship request by updating status to accepted
  # @return [Boolean] true if friendship was succesfully accepted, false if there was an error
  def accept
    update_attributes(:status => STATUS[:accepted])
  end

  # Declines a friendship request by updating status to accepted
  # @return [Boolean] true if friendship was succesfully accepted, false if there was an error
  def decline
    update_attributes(:status => STATUS[:declined])
  end

  # Declines a friendship request by updating status to accepted
  # @return [Boolean] true if friendship was succesfully accepted, false if there was an error
  def set_pending
    update_attributes(:status => STATUS[:pending])
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
    @inverse_friendship ||= Friendship.where({:friendee_id => friender_id, :friender_id => friendee_id}).first
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

  after_destroy :destroy_inverse_and_associations, :if => Proc.new {|friendship| !friendship.inverse_friendship.nil?}
  # TODO: make sure any necessary associations between friends are removed here
  # STAY ON TOP OF THIS!
  def destroy_inverse_and_associations
    # Destroy inverse friendship if it exists
    inverse_friendship.destroy if !inverse_friendship.nil?
  end

end
