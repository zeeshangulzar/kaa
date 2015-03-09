class ForumsController < ApplicationController

  respond_to :json
  
  authorize :index, :show, :public
  authorize :update, :create, :destroy, :upload, :master

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
