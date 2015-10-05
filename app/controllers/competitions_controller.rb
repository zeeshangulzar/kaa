class CompetitionsController < ApplicationController
  authorize :index, :show, :create, :update, :destroy, :master
  authorize :members, :coordinator

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.competitions : Competition
  end
  private :set_sandbox

  def index
    return HESResponder(@SB.all)
  end

  def show
    competition = @SB.find(params[:id]) rescue nil
    return HESResponder("Competition", "NOT_FOUND") if !competition
    return HESResponder(competition)
  end

  def create
    competition = nil
    Competition.transaction do
      competition = @SB.create(params[:competition])
    end
    return HESResponder("Error saving competition.", "ERROR") if !competition
    return HESResponder(competition.errors.full_messages, "ERROR") if !competition.valid?
    return HESResponder(competition)
  end

  def update
    competition = @SB.find(params[:id]) rescue nil
    return HESResponder("Competition", "NOT_FOUND") if !competition
    Competition.transaction do
      competition.update_attributes(params[:competition])
    end
    return HESResponder(competition.errors.full_messages, "ERROR") if !competition.valid?
    return HESResponder(competition)
  end

  def destroy
    competition = @SB.find(params[:id]) rescue nil
    return HESResponder("Competition", "NOT_FOUND") if !competition
    Competition.transaction do
      competition.destroy
    end
    return HESResponder(competition)
  end

  def members
    competition = @SB.find(params[:id]) rescue nil
    return HESResponder("Competition", "NOT_FOUND") if !competition
    return HESResponder(competition.members)
  end

end
