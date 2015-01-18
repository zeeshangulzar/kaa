class ChallengesSentController < ApplicationController
  authorize :all, :user
  wrap_parameters :challenge_sent

  def index
    if @target_user.id != @current_user.id && !@current_user.master?
      return HESResponder("You can't view other peoples challenges.", "DENIED")
    else
      return HESResponder(@target_user.challenges_sent)
    end
  end

  def show
    challenge_sent = ChallengeSent.find(params[:id])
    if !challenge_sent
      return HESResponder("Challenge", "NOT_FOUND")
    elsif (challenge_sent.user.id != @current_user.id) && !@current_user.master?
      return HESResponder("You may not view this challenge.", "DENIED")
    else
      return HESResponder(challenge_sent)
    end
  end

  def create
    challenge_sent = @current_user.challenges_sent.build(params[:challenge_sent])
    if !challenge_sent.valid?
      return HESResponder(challenge_sent.errors.full_messages, "ERROR")
    else
      if challenge_sent.user.id != @current_user.id && !@current_user.master?
        return HESResponder("Warning: Attempting impersonation. Activity logged.", "ERROR")
      end
      ChallengeSent.transaction do
        challenge_sent.save!
      end
      if !challenge_sent.errors.empty?
        return HESResponder(challenge_sent.errors.full_messages, "ERROR")
      end
      return HESResponder(challenge_sent)
    end
  end

  def update
    challenge_sent = ChallengeSent.find(params[:id]) rescue nil
    return HESResponder("Challenge", "NOT_FOUND") if !challenge_sent
    if challenge_sent.user_id != @current_user.id && !@current_user.master?
      return HESResponder("Not allowed.", "DENIED")
    end
    challenge_sent.update_attributes(params[:challenge_sent])
    if !challenge_sent.valid?
      return HESResponder(challenge_sent.errors.full_messages, "ERROR")
    end
    ChallengeSent.transaction do
      challenge_sent.save!
    end
    return HESResponder(challenge_sent)
  end

end