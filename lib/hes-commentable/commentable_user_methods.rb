module HesCommentable
  # Commentable module
  module CommentableUserMethods
    # When the module is included, it's extended with the instance methods
    # @param [ActiveRecord] base to extend
    def can_comment
      self.send :has_many, :comments, :conditions => {:is_deleted => false}, :dependent => :destroy
      self.send :include, InstanceMethods
    end

    # Module that includes instance methods for models that have comments
    module InstanceMethods


      # Creates a new comment
      # @param [Comment] comment that contains the content to create
      # @param [Commentable] commentable object that is being commented on
      # @return [Comment] comment that was just created
      # @example
      #  @user.comment("Like this recipe!", @recipe)
      #  @user.comment("Like this article").on(@article)
      def comment(comment, commentable = nil)
        _comment = self.comments.create(:content => comment)
        _comment.commentable = commentable
        _comment.save
        _comment
      end
    end
  end
end
