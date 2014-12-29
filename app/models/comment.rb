# A model that handles comments, including creating and marking as flagged or deleted.
class Comment < ApplicationModel
  include ActionView::Helpers

  belongs_to :commentable, :polymorphic => true
  belongs_to :user, :in_json => true

  attr_accessible :user, :content, :is_flagged, :is_deleted

  validates :content, :presence => true, :length => {:maximum => 420}
  
  scope :active, where(:is_deleted => false).order("last_modified_at DESC")
  scope :typed, lambda{|commentable_type| active.where(:commentable_type => commentable_type)}
  scope :by_promotion, lambda{|promotion| active.where(["users.promotion_id = ? || users.role = 'Poster'", promotion.id])}
  
  after_create :trigger_after_comment, :if => lambda { |comment| !comment.commentable.nil? }
  after_update :trigger_after_comment, :if => lambda { |comment| !comment.commentable.nil? && comment.commentable_id_was.nil? }
  after_destroy :trigger_after_uncomment

  acts_as_likeable

  # Overrides commentable built by polymorphic association in case commentable is not an ActiveRecord
  def commentable
    unless HesCommentable::ActsAsCommentable.non_active_record_commentables.collect(&:to_s).include?(self.commentable_type)
      super
    else
      HesCommentable::ActsAsCommentable.non_active_record_commentables.detect{|x| x.to_s == self.commentable_type}.find(self.commentable_id)
    end
  end

  # Overides serializable_hash so that time ago is included in hash
  def serializable_hash(options = nil)
    options = (options || {}).merge(:methods => [:time_ago])
    super
  end

  # Displays how long ago the comment was created in easy to read sentence
  # @return [String] sentence of how long ago comment was created
  def time_ago
    time_ago_in_words(self.created_at)
  end

  # Adds a commentable object to a comment. Syntactic sugar for chaining.
  # @param [Commentable] commentable object that is being commented on
  # @return [Comment] comment that just had a commentable object added to it
  # @example
  #  @comment.on(@recipe)
  #  @user.comment("Like this tip").on(@tip)
  def on(commentable)
    self.commentable_id = commentable.id
    self.commentable_type = commentable.class.to_s
    self.save
    self
  end

  # Fire the after_comment callbacks on commentable and user
  def trigger_after_comment
    commentable.send(:fire_after_comment, self) if commentable.respond_to?(:fire_after_comment)
    user.send(:fire_after_comment, self) if user.respond_to?(:fire_after_comment)
  end

  # Fire the after_comment callbacks on commentable and user
  def trigger_after_uncomment
    commentable.send(:fire_after_uncomment, self) if commentable.respond_to?(:fire_after_uncomment)
    user.send(:fire_after_uncomment, self) if user.respond_to?(:fire_after_uncomment)
  end
end