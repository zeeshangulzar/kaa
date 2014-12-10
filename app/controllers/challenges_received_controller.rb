class ChallengesReceivedController < ApplicationController
  authorize :all, :user

  def index
    c = @user.challenge_queue
    if params[:status]
      case params[:status]
        when 'all'
          c = @user.challenges_received
        when 'queue'
        else
          if ChallengeReceived::STATUS.stringify_keys.keys.include?(params[:status])
            # ?status=[new,accepted,etc.]
            c = @user.challenges_received.send(params[:status])
          elsif params[:status].is_i? && ChallengeReceived::STATUS.values.include?(params[:status].to_i)
            # ?status=[0,1,2,3,4]
            c = @user.challenges_received.send(ChallengeReceived::STATUS.index(params[:status].to_i).to_s)
          else
            return HESResponder("No such status.", "ERROR")
          end
      end
    end
    return HESResponder(c)
  end

  def show
    challenge_sent = ChallengeSent.find(params[:id])
    challenge = challenge_sent.challenge
    receivers = challenge_sent.receivers
    if !challenge
      return HESResponder("Challenge", "NOT_FOUND")
    elsif (challenge_sent.user != @user) && (!@user.coordinator? || !@user.master?)
      return HESResponder("You may not view this challenge.", "DENIED")
    else
      return HESResponder(challenge_sent)
    end
  end

  def create
    challenge = @promotion.challenges.build(params[:challenge])
    challenge.save
    return HESResponder(challenge)
  end

  def update
    challenge = Challenge.find(params[:id]) rescue nil
    if !challenge
      return HESResponder("Challenge", "NOT_FOUND")
    else
      if user != @user && !@user.master?
        return HESResponder("You may not edit this user.", "DENIED")
      end
      User.transaction do
        profile_data = !params[:user][:profile].nil? ? params[:user].delete(:profile) : []
        user.update_attributes(params[:user])
        user.profile.update_attributes(profile_data)
      end
      errors = user.profile.errors || user.errors # the order here is important. profile will have specific errors.
      if errors
        return HESResponder(errors.full_messages, "ERROR")
      else
        return HESResponder(user)
      end
    end
  end
end