class SuggestedChallengesController < ApplicationController
  authorize :index, :show, :create, :user
  authorize :update, :destroy, :location_coordinator
  
  
  def index
    if params[:promotion_id]
      return HESResponder(@promotion.suggested_challenges.order('created_at DESC'))
    elsif @current_user.id == @target_user.id || @current_user.location_coordinator?
      return HESResponder(@target_user.suggested_challenges)
    else
      return HESResponder("You may not other users' suggested challenges.", "DENIED")
    end
  end

  def show
    suggested_challenge = SuggestedChallenge.find(params[:id])
    if !suggested_challenge
      return HESResponder("Suggested Challenge", "NOT_FOUND")
    elsif !@current_user.location_coordinator? && suggested_challenge.user.id != @current_user.id
      return HESResponder("You may not view this challenge.", "DENIED")
    else
      return HESResponder(suggested_challenge)
    end
  end

  def create
    suggested_challenge = @target_user.suggested_challenges.build(params[:suggested_challenge])
    suggested_challenge.promotion_id = @promotion.id
    SuggestedChallenge.transaction do
      suggested_challenge.save
    end
    return HESResponder(suggested_challenge)
  end

  def update
    suggested_challenge = SuggestedChallenge.find(params[:id]) rescue nil
    if !suggested_challenge
      return HESResponder("Suggested Challenge", "NOT_FOUND")
    else
      if !@current_user.location_coordinator? && @current_user.id != suggested_challenge.user.id
        return HESResponder("You may not edit this challenge.", "DENIED")
      end
      suggested_challenge.promotion_id = @promotion.id
      SuggestedChallenge.transaction do
        suggested_challenge.update_attributes(params[:suggested_challenge])
      end
      if !suggested_challenge.valid?
        return HESResponder(suggested_challenge.errors.full_messages, "ERROR")
      else
        return HESResponder(suggested_challenge)
      end
    end
  end

  def destroy
    suggested_challenge = SuggestedChallenge.find(params[:id]) rescue nil
    if !suggested_challenge
      return HESResponder("Suggested Challenge", "NOT_FOUND")
    elsif (@current_user.location_coordinator? || @current_user.id == suggested_challenge.user.id) && suggested_challenge.destroy
      return HESResponder(suggested_challenge)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end
end