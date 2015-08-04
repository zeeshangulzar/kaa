class BehaviorsController < ApplicationController
  authorize :all, :master
  authorize :index, :user
  
  def index
    behaviors = !@promotion.nil? ? @promotion.behaviors : Behavior.all
    return HESResponder(behaviors)
  end

  def show
    behavior = Behavior.find(params[:id])
    return HESResponder(behavior)
  end

  def create
    Behavior.transaction do
      behavior = Behavior.create(params[:behavior])
    end
    return HESResponder(behavior)
  end

  def update
    behavior = Behavior.find(params[:id]) rescue nil
    return HESResponder("Behavior", "NOT_FOUND") if !behavior
    Behavior.transaction do
      behavior.update_attributes(params[:behavior])
    end
    return HESResponder(behavior)
  end

  def destroy
    behavior = Behavior.find(params[:id]) rescue nil
    return HESResponder("Behavior", "NOT_FOUND") if !behavior
    Behavior.transaction do
      behavior.destroy
    end
    return HESResponder(behavior)
  end
end