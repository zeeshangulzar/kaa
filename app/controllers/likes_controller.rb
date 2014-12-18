# Controller for handling all like requests
class LikesController < ApplicationController
  respond_to :json

  # Get the user before each request
  before_filter :get_likeable, :only => [:index, :create, :destroy]

  authorize :index, :create, :show, :user

  # for the user that created the like
  authorize :destroy, lambda{ |user, like, params| params[:id].nil? || like.user_id == user.id || user.role == "Master"}
  
  # Extra authorization parameters
  def authorization_parameters
    @like = Like.find_by_id(params[:id])
    [@like]
  end

  # Get the user or render an error
  #
  # @param [Integer] user id of the user with the likes
  def get_likeable
    if params[:likeable_id] && params[:likeable_type]
      @likeable = params[:likeable_type].singularize.camelcase.constantize.find(params[:likeable_id])
    elsif params[:action] == 'create'
      render :json => { :errors => ["Must pass likeable id"] }, :status => :unprocessable_entity 
    end
  end

  # Gets the list of likes for a user instance
  #
  # @url [GET] /recipes/1/likes
  # @url [GET] /likes
  # @authorize User
  # @param [String] likeable_type The type of model that has be liked
  # @param [Integer] likeable_id The id of model instance that has be liked
  # @return [Array] Array of all likes
  #
  # [URL] /:likeable_type/:likeable_id/likes [GET]
  # [URL] /likes [GET]
  #  [200 OK] Successfully retrieved Likes Array object
  #   # Example response
  #   [{
  #     "id": 1,
  #     "likeable_type": "Recipe",
  #     "likeable_id": 1,
  #     "user_id": 1,
  #     "likeable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/likes/1"
  #   }]
  def index
    @likes = @likeable ? @likeable.likes : params[:likeable_type] ? @user.likes.where(:likeable_type => params[:likeable_type]) : @user.likes
    respond_with @likes
  end

  # Gets a single like for a user
  #
  # @url [GET] /likes/1?user_id=1
  # @authorize User
  # @param [Integer] id The id of the like
  # @return [Like] Like that matches the id
  #
  # [URL] /likes/:id[GET]
  #  [200 OK] Successfully retrieved Like object
  #   # Example response
  #   {
  #     "id": 1,
  #     "likeable_type": "Recipe",
  #     "likeable_id": 1,
  #     "user_id": 1,
  #     "likeable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/likes/1"
  #   }
  def show
    @like = Like.find(params[:id])
    respond_with @like
  end

  # Creates a single like for a user
  #
  # @url [POST] /recipes/1/likes
  # @authorize User
  # @param [String] likeable_type The type of model that has be liked
  # @param [Integer] likeable_id The id of model instance that has be liked
  # @return [Like] Like that matches the id
  #
  # [URL] /:likeable_type/:likeable_id/likes [POST]
  #  [201 CREATED] Successfully created Like object
  #   # Example response
  #   {
  #     "id": 1,
  #     "likeable_type": "Recipe",
  #     "likeable_id": 1,
  #     "user_id": 1,
  #     "likeable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/likes/1"
  #   }
  def create
    @like = @user.likes.build
    @like.likeable_id = @likeable.id
    @like.likeable_type = @likeable.class.to_s
    @like.save
    respond_with @like
  end

  # Deletes a single like from a user
  #
  # @url [DELETE] /likes/1
  # @authorize User The user that owns the like can delete it
  # @authorize Master
  # @param [Integer] id The id of the like
  # @return [Like] Like that was just deleted
  #
  # [URL] /likes/:id [DELETE]
  #  [200 OK] Successfully destroyed Like object
  #   # Example response
  #   {
  #     "id": 1,
  #     "likeable_type": "Recipe",
  #     "likeable_id": 1,
  #     "user_id": 1,
  #     "likeable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/likes/1"
  #   }
  def destroy
    @like = params[:id].nil? ? @likeable.likes.where(:user_id => get_user.id).first : Like.find(params[:id])
    @like.destroy
    respond_with @like
  end
end