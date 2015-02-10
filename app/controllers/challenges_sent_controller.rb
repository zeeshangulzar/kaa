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
    challenge_sent_user_ids = params[:challenge_sent].delete(:to_user_id)
    challenge_sent_group_ids = params[:challenge_sent].delete(:to_group_id)
    challenge_sent = @current_user.challenges_sent.build(params[:challenge_sent])
    if !challenge_sent.valid?
      return HESResponder(challenge_sent.errors.full_messages, "ERROR")
    else
      if challenge_sent.user.id != @current_user.id && !@current_user.master?
        return HESResponder("Warning: Attempting impersonation. Activity logged.", "ERROR")
      end
      ChallengeSent.transaction do
        challenge_sent.save!
        # TODO: any point in validate groups and users? challenge_sent.validate_users_and_groups()
        challenge_sent.build_users_and_groups({:group_ids => challenge_sent_group_ids, :user_ids => challenge_sent_user_ids})
        if challenge_sent.challenged_users.size < 1
          raise ActiveRecord::Rollback
        end
        challenge_sent.create_challenges_received
      end
      return HESResponder(challenge_sent.errors.full_messages, "ERROR") if !challenge_sent.valid?
      return HESResponder("You must challenge at least 1 user", "ERROR") if challenge_sent.challenged_users.size < 1
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

  def validate
    challenge_sent_user_ids = params[:challenge_sent].delete(:to_user_id)
    challenge_sent_group_ids = params[:challenge_sent].delete(:to_group_id)
    challenge_sent = @current_user.challenges_sent.build(params[:challenge_sent])
    if !challenge_sent.valid?
      return HESResponder(challenge_sent.errors.full_messages, "ERROR")
    else
      if challenge_sent.user.id != @current_user.id && !@current_user.master?
        return HESResponder("Warning: Attempting impersonation. Activity logged.", "ERROR")
      end
      invalid = challenge_sent.check_users_and_groups({:group_ids => challenge_sent_group_ids, :user_ids => challenge_sent_user_ids})
    end
    if !invalid[:groups].empty? || !invalid[:users].empty?
      return HESResponder(invalid, "ERROR")
    else
      return HESResponder("AOK")
    end
  end
end