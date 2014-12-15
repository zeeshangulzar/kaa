class ChallengesSentController < ApplicationController
  authorize :all, :user

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
      if challenge_sent.challenged_group
        # challenge_sent is a group of users, create challenges_sent for each user in group
        css = []
        ChallengeSent.transaction do
          # TODO: should these all be in a single tx?
          challenge_sent.challenged_group.users.each do |u|
            cs = @current_user.challenges_sent.build(params[:challenge_sent])
            cs.to_user_id = u.id
            if !cs.valid?
              return HESResponder(cs.errors.full_messages, "ERROR") if !cs.errors.empty?
            else
              cs.save!
              css.push(cs)
            end
          end
        end
        return HESResponder(css)
      else
        ChallengeSent.transaction do
          challenge_sent.save!
        end
        if !challenge_sent.errors.empty?
          return HESResponder(challenge_sent.errors.full_messages, "ERROR")
        end
        return HESResponder(challenge_sent)
      end
    end
  end

  def update
    # TODO: make me
  end

  def destroy
    # TODO: make me
  end
end