class ChallengesController < ApplicationController
  
  authorize :index, :show, :user
  authorize :create, :update, :destroy, :coordinator
  
  def index
    if @current_user.location_coordinator_or_above?
      challenges = @promotion.challenges
    else
      # regular user should only see active challenges
      challenges = @promotion.challenges.active(@promotion).where(:location_id => [nil, @current_user.location_id, @current_user.top_level_location_id])
    end
    if params[:type]
      if Challenge::TYPE.stringify_keys.keys.include?(params[:type])
        # ?type=[peer,regional,etc.]
        if params[:type] == 'regional'
          # only return regional challenges that the user isn't currently working towards
          challenges = challenges.regional.select{|challenge| !@current_user.accepted_and_completed_challenges.collect{|ac|ac.challenge.id}.include?(challenge.id) }
        else
          challenges = challenges.send(params[:type])
        end
      else
        return HESResponder("No such type.", "ERROR")
      end
    end
    return HESResponder(challenges)
  end

  def show
    challenge = Challenge.find(params[:id]) rescue nil
    if !challenge
      return HESResponder("Challenge", "NOT_FOUND")
    elsif (challenge.promotion != @current_user.promotion) && !@current_user.master?
      return HESResponder("You may not view this challenge.", "DENIED")
    elsif (!challenge.location_id.nil? && !@current_user.location_ids.include?(challenge.location_id)) && !@current_user.sub_promotion_coordinator_or_above?
      return HESResponder("You may not view this challenge.", "DENIED")
    elsif !challenge.is_active? && !@current_user.location_coordinator_or_above?
      # respect the visible from/to dates..
      return HESResponder("Challenge inactive.", "DENIED")
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
      if (!challenge.location_id.nil? && @current_user.location_ids.include?(challenge.location_id) && @current_user.location_coordinator_or_above?) || (@current_user.sub_promotion_coordinator_or_above? && @current_user.promotion_id == challenge.promotion_id) || @current_user.master?
        Challenge.transaction do
          challenge.update_attributes(params[:challenge])
        end
      else
        return HESResponder("You may not edit this challenge.", "DENIED")
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
    elsif (@current_user.location_coordinator_or_above? && !challenge.location_id.nil? && @current_user.location_ids.include?(challenge.location_id)) || (challenge.promotion_id == @current_user.promotion_id && @current_user.sub_promotion_coordinator_or_above?) || @current_user.master?
      challenge.destroy
      return HESResponder(challenge)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end
end