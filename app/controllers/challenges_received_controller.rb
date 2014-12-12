class ChallengesReceivedController < ApplicationController
  authorize :all, :user

  def index
    if @target_user.id != @current_user.id && !@current_user.master?
      return HESResponder("You can't view other peoples challenges.", "DENIED")
    else
      c = user.challenge_queue
      if params[:status]
        case params[:status]
          when 'all'
            c = user.challenges_received
          when 'queue'
          else
            if ChallengeReceived::STATUS.stringify_keys.keys.include?(params[:status])
              # ?status=[new,accepted,etc.]
              c = user.challenges_received.send(params[:status])
            elsif params[:status].is_i? && ChallengeReceived::STATUS.values.include?(params[:status].to_i)
              # ?status=[0,1,2,3,4]
              c = user.challenges_received.send(ChallengeReceived::STATUS.index(params[:status].to_i).to_s)
            else
              return HESResponder("No such status.", "ERROR")
            end
        end
      end
      return HESResponder(c)
    end
  end

  def show
    challenge_sent = ChallengeSent.find(params[:id])
    challenge = challenge_sent.challenge
    receivers = challenge_sent.receivers
    if !challenge
      return HESResponder("Challenge", "NOT_FOUND")
    elsif (challenge_sent.user != @current_user) && (!@current_user.coordinator? || !@current_user.master?)
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
    # TODO: make me
  end

  def destroy
    # TODO: make me
  end
end