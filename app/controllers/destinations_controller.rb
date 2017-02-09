class DestinationsController < ApplicationController
  authorize :index, :show, :user_destinations, :answer, :user
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
      if params[:map_id]
        @SB = Map.find(params[:map_id]).destinations rescue nil
        return HESResponder("Map", "NOT_FOUND") if @SB.nil?
      else
        @SB = Destination
      end
    end
  end
  private :set_sandbox

  def index
    # TODO: need a nice CONSISTENT way to handle statuses across models
    # using params, taking into account role, and don't forget caching!
    scope = record_status_scope(Destination::STATUS[:active])
    return HESResponder(@SB.send(*scope))
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

  def user_destinations
    if !@current_user.master? && params[:user_id].to_i != @current_user.id
      return HESResponder("You can't have this.", "UNAUTHORIZED")
    end
    destination_id = nil
    if params[:destination_id]
      destination_id = params[:destination_id].to_i
    end
    return HESResponder(Destination.user_destinations(params[:user_id].to_i, destination_id))
  end

  def answer
    destination = Destination.find(params[:destination_id])
    answer = @current_user.user_answers.where(:destination_id => destination.id).first rescue nil
    if answer.nil?
      answer = @current_user.user_answers.create(:destination_id => destination.id, :answer => params[:answer], :is_correct => destination.check_answer(params[:answer]))
    else
      return HESResponder("You've already answered this quiz.", "ERROR")
    end
    return HESResponder(Destination.user_destinations(@current_user, destination.id))
  end

end