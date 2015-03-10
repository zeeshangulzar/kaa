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

  def get_shareable
    if params[:shareable_id] && params[:shareable_type]
      @shareable = params[:shareable_type].singularize.camelcase.constantize.find(params[:shareable_id])
    elsif params[:action] == 'create'
      return HESResponder("Must pass shareable id", "ERROR")
    end
  end

  def index
    @shares = @shareable ? @shareable.shares : params[:shareable_type] ? @current_user.shares.where(:shareable_type => params[:shareable_type]) : @current_user.shares
    return HESResponder(@shares)
  end

  def show
    @share = Share.find(params[:id])
    return HESResponder(@share)
  end

  def create
    @share = @current_user.shares.build
    @share.shareable_id = @shareable.id
    @share.shareable_type = @shareable.class.name.to_s
    @share.via = !params[:via].nil? ? params[:via] : 'unknown'
    @share.save
    return HESResponder(@share)
  end

  def destroy
    @share = params[:id].nil? ? @shareable.shares.where(:user_id => @current_user.id).first : Share.find(params[:id])
    @share.destroy
    return HESResponder(@share)
  end
end