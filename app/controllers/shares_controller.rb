# Controller for handling all share requests
class SharesController < ApplicationController
  respond_to :json

  # Get the user before each request
  before_filter :get_shareable, :only => [:index, :create, :destroy]

  authorize :create, :user
  authorize :index, :show, :coordinator
  
  # Extra authorization parameters
  def authorization_parameters
    @share = Share.find_by_id(params[:id])
    [@share]
  end

  # Get the user or render an error
  #
  # @param [Integer] user id of the user with the shares
  def get_shareable
    if params[:shareable_id] && params[:shareable_type]
      @shareable = params[:shareable_type].singularize.camelcase.constantize.find(params[:shareable_id])
    elsif params[:action] == 'create'
      render :json => { :errors => ["Must pass shareable id"] }, :status => :unprocessable_entity
    end
  end

  # Gets the list of shares for a user instance
  #
  # @url [GET] /recipes/1/shares
  # @url [GET] /shares
  # @authorize User
  # @param [String] shareable_type The type of model that has be shared
  # @param [Integer] shareable_id The id of model instance that has be shared
  # @return [Array] Array of all shares
  #
  # [URL] /:shareable_type/:shareable_id/shares [GET]
  # [URL] /shares [GET]
  #  [200 OK] Successfully retrieved Shares Array object
  #   # Example response
  #   [{
  #     "id": 1,
  #     "shareable_type": "Recipe",
  #     "shareable_id": 1,
  #     "user_id": 1,
  #     "shareable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/shares/1"
  #   }]
  def index
    @shares = @shareable ? @shareable.shares : params[:shareable_type] ? @current_user.shares.where(:shareable_type => params[:shareable_type]) : @current_user.shares
    return HESResponder(@shares)
  end

  # Gets a single share for a user
  #
  # @url [GET] /shares/1?user_id=1
  # @authorize User
  # @param [Integer] id The id of the share
  # @return [Share] Share that matches the id
  #
  # [URL] /shares/:id[GET]
  #  [200 OK] Successfully retrieved Share object
  #   # Example response
  #   {
  #     "id": 1,
  #     "shareable_type": "Recipe",
  #     "shareable_id": 1,
  #     "user_id": 1,
  #     "shareable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/shares/1"
  #   }
  def show
    @share = Share.find(params[:id])
    return HESResponder(@share)
  end

  # Creates a single share for a user
  #
  # @url [POST] /recipes/1/shares
  # @authorize User
  # @param [String] shareable_type The type of model that has be shared
  # @param [Integer] shareable_id The id of model instance that has be shared
  # @return [Share] Share that matches the id
  #
  # [URL] /:shareable_type/:shareable_id/shares [POST]
  #  [201 CREATED] Successfully created Share object
  #   # Example response
  #   {
  #     "id": 1,
  #     "shareable_type": "Recipe",
  #     "shareable_id": 1,
  #     "user_id": 1,
  #     "shareable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/shares/1"
  #   }
  def create
    @share = @current_user.shares.build
    @share.shareable_id = @shareable.id
    @share.shareable_type = @shareable.class.name.to_s
    @share.via = !params[:via].nil? ? params[:via] : 'unknown'
    @share.save
    return HESResponder(@share)
  end

  # Deletes a single share from a user
  #
  # @url [DELETE] /shares/1
  # @authorize User The user that owns the share can delete it
  # @authorize Master
  # @param [Integer] id The id of the share
  # @return [Share] Share that was just deleted
  #
  # [URL] /shares/:id [DELETE]
  #  [200 OK] Successfully destroyed Share object
  #   # Example response
  #   {
  #     "id": 1,
  #     "shareable_type": "Recipe",
  #     "shareable_id": 1,
  #     "user_id": 1,
  #     "shareable": {...},
  #     "user": {...},
  #     "created_at": "2013-09-04T10:13:24-04:00",
  #     "updated_at": "2013-09-04T10:13:24-04:00",
  #     "url": "http://api.hesapps.com/shares/1"
  #   }
  def destroy
    @share = params[:id].nil? ? @shareable.shares.where(:user_id => get_user.id).first : Share.find(params[:id])
    @share.destroy
    return HESResponder(@share)
  end
end