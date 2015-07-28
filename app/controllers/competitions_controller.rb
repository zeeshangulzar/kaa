class CompetitionsController < ApplicationController

  def index
    return HESResponder(@promotion.competitions)
  end

  def show
    competition = Competition.find(params[:id])
    return HESResponder(competition)
  end

  def create
    Competition.transaction do
      competition = @promotion.competitions.create(params[:competition])
    end
    return HESResponder(competition.errors.full_messages, "ERROR") if !competition.valid?
    return HESResponder(competition)
  end

  def update
    competition = Competition.find(params[:id])
    Competition.transaction do
      competition.update_attributes(params[:competition])
    end
    return HESResponder(competition.errors.full_messages, "ERROR") if !competition.valid?
    return HESResponder(competition)
  end

  def destroy
    competition = Competition.find(params[:id])
    Competition.transaction do
      competition.destroy
    end
    return HESResponder(competition)
  end
end
