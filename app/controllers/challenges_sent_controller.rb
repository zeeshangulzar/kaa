class ChallengesSentController < ApplicationController
  authorize :all, :user

  def index
    user = User.find(params[:user_id]) rescue nil
    if !user
      return HESResponder("User", "NOT_FOUND")
    elsif @user.id != user.id && !@user.master?
      return HESResponder("You can't view other peoples challenges.", "DENIED")
    else
      return HESResponder(user.challenges_sent)
    end
  end

  def show
    challenge_sent = ChallengeSent.find(params[:id])
    challenge = challenge_sent.challenge
    receivers = challenge_sent.receivers
    if !challenge
      return HESResponder("Challenge", "NOT_FOUND")
    elsif (challenge_sent.user.id != @user.id) && (!@user.coordinator? || !@user.master?)
      return HESResponder("You may not view this challenge.", "DENIED")
    else
      return HESResponder(challenge_sent)
    end
  end

  def create
    challenge_sent = ChallengeSent.new(params[:challenge_sent])
    if !challenge_sent.valid?
      return HESResponder(challenge_sent.errors.full_messages, "ERROR")
    else
      if challenge_sent.user.id != @user.id && !@user.master?
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