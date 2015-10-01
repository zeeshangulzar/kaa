class BehaviorsController < ApplicationController
  authorize :all, :reorder, :master
  authorize :index, :show, :user

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.gifts : Gift
  end
  private :set_sandbox
  
  def index
    return HESResponder(@SB.all)
  end

  def show
    behavior = @SB.find(params[:id]) rescue nil
    return HESResponder("Behavior", "NOT_FOUND") if !behavior
    return HESResponder(behavior)
  end

  def create
    behavior = nil;
    Behavior.transaction do
      behavior = @SB.create(params[:behavior])
    end
    return HESResponder(behavior.errors.full_messages, "ERROR") if !behavior.valid?
    return HESResponder(behavior)
  end

  def update
    behavior = @SB.find(params[:id]) rescue nil
    return HESResponder("Behavior", "NOT_FOUND") if !behavior
    Behavior.transaction do
      behavior.update_attributes(params[:behavior])
    end
    return HESResponder(behavior.errors.full_messages, "ERROR") if !behavior.valid?
    return HESResponder(behavior)
  end

  def destroy
    behavior = @SB.find(params[:id]) rescue nil
    return HESResponder("Behavior", "NOT_FOUND") if !behavior
    Behavior.transaction do
      behavior.destroy
    end
    return HESResponder(behavior)
  end

  def reorder
    return HESResponder("Must provide sequence.", "ERROR") if params[:sequence].nil? || !params[:sequence].is_a?(Array)
    behaviors = @SB.all

    behavior_ids = behaviors.collect{|behavior|behavior.id}
    return HESResponder("Behavior ids are mismatched.", "ERROR") if (behavior_ids & params[:sequence]) != behavior_ids
    sequence = 0
    params[:sequence].each{ |behavior_id|
      behavior = Behavior.find(behavior_id)
      behavior.update_attributes(:sequence => sequence)
      sequence += 1
    }
    Behavior.uncached do
      behaviors = @SB.all
    end
    return HESResponder(behaviors)
  end
end