class ForumsController < ApplicationController

  respond_to :json
  
  authorize :index, :show, :public
  authorize :update, :create, :destroy, :upload, :location_coordinator

  def index
    return HESResponder("Location", "NOT_FOUND") if params[:location_id].nil?
    location = Location.find(params[:location_id]) rescue nil
    return HESResponder("Location", "NOT_FOUND") if !location
    forums = location.forums
    return HESResponder(forums)
  end

  def show
    forum = Forum.find(params[:id]) rescue nil
    return HESResponder("Forum", "NOT_FOUND") if !forum
    return HESResponder(forum)
  end

  def create
    location = Location.find(params[:location_id] || params[:forum][:location_id]) rescue nil
    return HESResponder("Location", "NOT_FOUND") if !location
    return HESResponder("You cannot create a forum.", "DENIED") if !@current_user.location_ids.include?(location.id) && !@current_user.coordinator_or_above?
    forum = nil
    Forum.transaction do
      forum = location.forums.create(params[:forum])
      return HESResponder(forum.errors.full_messages, "ERROR") if !forum.valid?
    end
    return HESResponder(forum)
  end

  def update
    forum = Forum.find(params[:id]) rescue nil
    return HESResponder("Forum", "NOT_FOUND") if !forum
    return HESResponder("You cannot update a forum.", "DENIED") if !@current_user.location_ids.include?(forum.location_id) && !@current_user.coordinator_or_above?
    Forum.transaction do
      forum.update_attributes(params[:forum])
    end
    return HESResponder(forum)
  end

  def destroy
    forum = Forum.find(params[:id]) rescue nil
    return HESResponder("Forum", "NOT_FOUND") if !forum
    if forum.destroy
      return HESResponder(forum)
    else
      return HESResponder("could not delete forum.", "ERROR")
    end
  end

end
