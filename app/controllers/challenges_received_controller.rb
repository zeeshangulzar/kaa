class ChallengesReceivedController < ApplicationController
  authorize :all, :user
  wrap_parameters :challenge_received

  def index
    if @target_user.id != @current_user.id && !@current_user.master?
      return HESResponder("You can't view other peoples challenges.", "DENIED")
    else
      c = @target_user.challenge_queue # see user.rb
      if params[:status]
        case params[:status]
          when 'all'
            c = @target_user.challenges_received
          when 'queue'
          when 'expired', '5'
            # expired should only be accepted and expired, see user.rb
            c = @target_user.expired_challenges
          when 'accepted', '2'
            # we don't want expired accepted, see user.rb
            c = @target_user.unexpired_challenges.accepted
          else
            if ChallengeReceived::STATUS.stringify_keys.keys.include?(params[:status])
              # ?status=[unseen,accepted,etc.]
              c = @target_user.challenges_received.send(params[:status])
            elsif params[:status].is_i? && ChallengeReceived::STATUS.values.include?(params[:status].to_i)
              # ?status=[0,1,2,3,4]
              c = @target_user.challenges_received.send(ChallengeReceived::STATUS.index(params[:status].to_i).to_s)
            else
              return HESResponder("No such status.", "ERROR")
            end
        end
      end
      return HESResponder(c)
    end
  end

  def show
    challenge_received = ChallengeReceived.find(params[:id])
    if !challenge_received
      return HESResponder("Challenge", "NOT_FOUND")
    elsif (challenge_received.user.id != @current_user.id) && !@current_user.master?
      return HESResponder("You may not view this challenge.", "DENIED")
    else
      return HESResponder(challenge_received)
    end
  end

  def create
    if params[:challenge_received] && params[:challenge_received][:status] && [ChallengeReceived::STATUS[:accepted], ChallengeReceived::STATUS[:completed]].include?(params[:challenge_received][:status]) && @current_user.accepted_challenges.size >= 4
      return HESResponder("Can't accept anymore challenges.", "ERROR")
    end
    challenge_received = @current_user.challenges_received.build(params[:challenge_received])
    if !challenge_received.valid?
      return HESResponder(challenge_received.errors.full_messages, "ERROR")
    else
      ChallengeReceived.transaction do
        challenge_received.save!
      end
      return HESResponder(challenge_received)
    end
  end

  def update
    challenge_received = ChallengeReceived.find(params[:id]) rescue nil
    if !challenge_received
      return HESResponder("Challenge", "NOT_FOUND")
    else
      if @current_user.id != challenge_received.user.id && !@current_user.master?
        return HESResponder("You may not edit this challenge.", "DENIED")
      end
      return HESResponder("Challenge expired.", "ERROR") if challenge_received.expired?
      if params[:challenge_received] && params[:challenge_received][:status] && [ChallengeReceived::STATUS[:accepted], ChallengeReceived::STATUS[:completed]].include?(params[:challenge_received][:status]) && @current_user.accepted_challenges.size >= 4 && !@current_user.accepted_challenges.include?(challenge_received)
        return HESResponder("Can't accept anymore challenges.", "ERROR")
      end
      ChallengeReceived.transaction do
        challenge_received.update_attributes(params[:challenge_received])
      end
      if !challenge_received.valid?
        return HESResponder(challenge_received.errors.full_messages, "ERROR")
      else
        return HESResponder(challenge_received)
      end
    end
  end

  def destroy
    # TODO: make me
  end
end