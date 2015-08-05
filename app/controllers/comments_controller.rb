# Controller for handling all comment requests
class CommentsController < ApplicationController
  respond_to :json

  # Get the user before each request
  before_filter :get_commentable, :only => [:index, :create]

  authorize :index, :show, :create, :user

  # Allow updates for is_flagged set to true from any user, any other update requires master
  authorize :update, :user, lambda { |user, comment, params|
    if params[:comment].keys.size >= 1
      if params[:comment].has_key?(:is_flagged)
        if params[:comment][:is_flagged] == "false" || params[:comment][:is_flagged] == false
          return user.role == "Master"
        elsif comment.user_id == user.id
          return false
        else
          comment_params = params.delete(:comment)
          params[:comment] = {:is_flagged => comment_params[:is_flagged]}
          return true
        end
      end
    end
    return comment.user_id == user.id || user.role == "Master"
  }

  # for user that owns the comment
  authorize :destroy, lambda { |user, comment, params| comment.user_id == user.id || user.role == 'Master'}

  # Extra authorize parameters
  def authorization_parameters
    @comment = Comment.find_by_id(params[:id])
    [@comment]
  end

  # Get the user or render an error
  #
  # @param [Integer] user id of the user with the comments
  def get_commentable
    unless params[:commentable_id].nil?
      @commentable = params[:commentable_type].singularize.camelcase.constantize.find(params[:commentable_id])
    else
      return HESResponder("Must pass commentable id", "ERROR")
    end
  end

  def index
    comments = @commentable.comments
    return HESResponder(comments)
  end

  def show
    comment = Comment.find(params[:id]) rescue nil
    return HESResponder("Comment", "NOT_FOUND") if !comment
    return HESResponder(comment)
  end

  def create
    comment = @current_user.comments.build(params[:comment])
    comment.commentable_type = @commentable.class.to_s
    comment.commentable_id = @commentable.id
    return HESResponder(comment.errors.full_messages, "ERROR") if !comment.valid?
    Comment.transaction do
      comment.save
    end
    return HESResponder(comment)
  end

  def update
    @comment ||= Comment.find(params[:id]) rescue nil
    return HESResponder("Comment", "NOT_FOUND") if !@comment
    Comment.transaction do
      @comment.update_attributes(params[:comment])
      return HESResponder(@comment.errors.full_messages, "ERROR") if !@comment.valid?
    end
    return HESResponder(@comment)
  end

  def destroy
  	@comment ||= Comment.find(params[:id]) rescue nil
    return HESResponder("Comment", "NOT_FOUND") if !@comment
    Comment.transaction do
      @comment.destroy
    end
  	return HESResponder(@comment)
  end
end