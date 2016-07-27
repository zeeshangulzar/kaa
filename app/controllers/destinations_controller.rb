class DestinationsController < ApplicationController
  authorize :index, :show, :user
  authorize :create, :update, :destroy, :master

  before_filter :set_sandbox, :only => [:index, :create]
  def set_sandbox
    if use_sandbox?
      if params[:map_id]
        @SB = @promotion.maps.active.find(params[:map_id]).destinations rescue nil
        return HESResponder("Map", "NOT_FOUND") if @SB.nil?
      else
        return HESResponder("Map required.", "ERROR")
      end
    else
      @SB = Destination
    end
  end
  private :set_sandbox

  def index
    # TODO: need a nice CONSISTENT way to handle statuses across models
    # using params, taking into account role, and don't forget caching!
    scope = model_status_scope(Destination::STATUS[:active])
    return HESCachedResponder(Destination.collection_cache_key(scope, @SB.send(*scope)), 'ignore_me', {:page_size => 0}) do
      @SB.send(*scope)
    end
  end

  def show
    @SB = Destination.active
    if @current_user.master?
      @SB = Destination
    end
    destination = @SB.find(params[:id]) rescue nil
    return HESResponder("Destination", "NOT_FOUND") if destination.nil?
    return HESResponder("Destination", "NOT_FOUND") if !@current_user.master? && !@promotion.maps.include?(destination.map)
    return HESResponder(destination)
  end

  def create
    destination = nil
    Destination.transaction do
      destination = @SB.new(params[:destination]) rescue nil
      return HESResponder(destination.errors.full_messages, "ERROR") if !destination.valid?
      destination.save!
    end
    return HESResponder(destination)
  end

  def update
    destination = Destination.find(params[:id]) rescue nil
    return HESResponder("Destination", "NOT_FOUND") if destination.nil?
    Destination.transaction do
      destination.update_attributes(params[:destination])
    end
    return HESResponder(destination)
  end

  def destroy
    destination = Destination.find(params[:id]) rescue nil
    return HESResponder("Destination", "NOT_FOUND") if destination.nil?
    Destination.transaction do
      destination.destroy
    end
    return HESResponder(destination)
  end

end