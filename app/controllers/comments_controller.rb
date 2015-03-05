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

  # Gets the list of comments for a user instance
  #
  # @url [GET] /recipes/1/comments
  # @url [GET] /comments
  # @authorize User
  # @param [String] commentable_type The type of model that has be commented
  # @param [Integer] commentable_id The id of model instance that has be commented
  # @return [Array] Array of all comments
  #
  # [URL] /:commentable_type/:commentable_id/comments [GET]
  # [URL] /comments [GET]
  #  [200 OK] Successfully retrieved Comments Array object
  #   # Example response
  #   [{
  #     "id": 1,
  #     "content": "Wow! This looks like a great recipe!",
  #     "commentable_type": "Recipe",
  #     "commentable_id": 1,
  #     "user_id": 1,
  #     "commentable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/comments/1"
  #   }]
  def index
    comments = @commentable.comments
    return HESResponder(comments)
  end

  # Gets a single comment for a user
  #
  # @url [GET] /comments/1?user_id=1
  # @authorize User
  # @param [Integer] id The id of the comment
  # @return [Comment] Comment that matches the id
  #
  # [URL] /comments/:id[GET]
  #  [200 OK] Successfully retrieved Comment object
  #   # Example response
  #   {
  #     "id": 1,
  #     "content": "Wow! This looks like a great recipe!",
  #     "commentable_type": "Recipe",
  #     "commentable_id": 1,
  #     "user_id": 1,
  #     "commentable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/comments/1"
  #   }
  def show
    comment = Comment.find(params[:id])
    return HESResponder(comment)
  end

  # Creates a single comment for a user
  #
  # @url [POST] /recipes/1/comments
  # @authorize User
  # @param [String] commentable_type The type of model that has be commented
  # @param [Integer] commentable_id The id of model instance that has be commented
  # @return [Comment] Comment that matches the id
  #
  # [URL] /:commentable_type/:commentable_id/comments/1 [POST]
  #  [201 CREATED] Successfully created Comment object
  #   # Example response
  #   {
  #     "id": 1,
  #     "content": "Wow! This looks like a great recipe!",
  #     "commentable_type": "Recipe",
  #     "commentable_id": 1,
  #     "user_id": 1,
  #     "commentable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/comments/1"
  #   }
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

  # Updates a single comment for a user
  #
  # @url [PUT] /recipes/1/comments
  # @authorize User can flag a comment
  # @authorize Master can flag and unflag a comment
  # @param [Integer] id The id of the comment
  # @param [Boolean] is_flagged Whether or not the comment is flagged
  # @return [Comment] Comment that matches the id
  #
  # [URL] /comments/:id [POST]
  #  [201 CREATED] Successfully created Comment object
  #   # Example response
  #   {
  #     "id": 1,
  #     "content": "Wow! This looks like a great recipe!",
  #     "commentable_type": "Recipe",
  #     "commentable_id": 1,
  #     "user_id": 1,
  #     "commentable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/comments/1"
  #   }
  def update
    @comment ||= Comment.find(params[:id])
    return HESResponder(!comment.errors.full_messages, "ERROR") if !@comment.valid?
    Comment.transaction do
      @comment.update_attributes(params[:comment])
    end
    return HESResponder(@comment)
  end

  # Deletes a single comment from a user
  #
  # @url [DELETE] /comments/1
  # @authorize User The user that owns the comment can delete it
  # @authorize Master
  # @param [Integer] id The id of the comment
  # @return [Comment] Comment that was just deleted
  #
  # [URL] /comments/:id [DELETE]
  #  [200 OK] Successfully destroyed Comment object
  #   # Example response
  #   {
  #     "id": 1,
  #     "content": "Wow! This looks like a great recipe!",
  #     "commentable_type": "Recipe",
  #     "commentable_id": 1,
  #     "user_id": 1,
  #     "commentable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/comments/1"
  #   }
  def destroy
  	@comment ||= Comment.find(params[:id])
  	@comment.destroy
  	return HESResponder(@comment)
  end
end