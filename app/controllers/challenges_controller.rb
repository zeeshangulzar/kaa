class ChallengesController < ApplicationController
  
  authorize :index, :show, :user
  authorize :create, :update, :destroy, :coordinator
  
  def index
    return HESResponder(@promotion.challenges)
  end

  def show
    challenge = Challenge.find(params[:id])
    if !challenge
      return HESResponder("Challenge", "NOT_FOUND")
    elsif (challenge.promotion != @current_user.promotion || (challenge.location && challenge.location != @current_user.location))  && !@current_user.master?
      return HESResponder("You may not view this challenge.", "DENIED")
    else
      return HESResponder(challenge)
    end
  end

  def create
    challenge = @promotion.challenges.build(params[:challenge])
    Challenge.transaction do
      challenge.save
    end
    return HESResponder(challenge)
  end

  def update
    challenge = Challenge.find(params[:id]) rescue nil
    if !challenge
      return HESResponder("Challenge", "NOT_FOUND")
    else
      if !@current_user.location_coordinator?
        return HESResponder("You may not edit this challenge.", "DENIED")
      end
      Challenge.transaction do
        challenge.update_attributes(params[:challenge])
      end
      if !challenge.valid?
        return HESResponder(challenge.errors.full_messages, "ERROR")
      else
        return HESResponder(challenge)
      end
    end
  end

  def destroy
    challenge = Challenge.find(params[:id]) rescue nil
    if !challenge
      return HESResponder("Challenge", "NOT_FOUND")
    elsif @current_user.location_coordinator? && challenge.destroy
      return HESResponder(challenge)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end
end