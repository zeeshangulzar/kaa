class LevelsController < ApplicationController
  authorize :all, :master
  authorize :index, :show, :user

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.levels : Level
  end
  private :set_sandbox
  
  def index
    return HESResponder(@SB.all)
  end

  def show
    level = @SB.find(params[:id]) rescue nil
    return HESResponder("Level", "NOT_FOUND") if !level
    return HESResponder(level)
  end

  def create
    level = nil;
    Level.transaction do
      level = @SB.create(params[:level])
    end
    return HESResponder(level.errors.full_messages, "ERROR") if !level.valid?
    return HESResponder(level)
  end

  def update
    level = @SB.find(params[:id]) rescue nil
    return HESResponder("Level", "NOT_FOUND") if !level
    Level.transaction do
      level.update_attributes(params[:level])
    end
    return HESResponder(level.errors.full_messages, "ERROR") if !level.valid?
    return HESResponder(level)
  end

  def destroy
    level = @SB.find(params[:id]) rescue nil
    return HESResponder("Level", "NOT_FOUND") if !level
    Level.transaction do
      level.destroy
    end
    return HESResponder(level)
  end

end