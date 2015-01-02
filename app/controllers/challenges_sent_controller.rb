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


#      if challenge_sent.challenged_group
#        # challenge_sent is a group of users, create challenges_sent for each user in group
#        css = []
#        ChallengeSent.transaction do
#          # TODO: should these all be in a single tx?
#          challenge_sent.challenged_group.users.each do |u|
#            challenge_received = ChallengeReceived.where(:challenge_id => challenge_sent.challenge_id, :user_id => u.id).where("(expires_on IS NULL OR expires_on > ?) AND status IN (?)", @promotion.current_date, [ChallengeReceived::STATUS[:unseen], ChallengeReceived::STATUS[:pending], ChallengeReceived::STATUS[:accepted]]).first
#            if challenge_received
#              cs = @current_user.challenges_sent.where("challenge_id = ? AND to_user_id = ? AND DATE(created_at) = ?", challenge_sent.challenge_id, u.id, @promotion.current_date).first
#            else
#              cs = @current_user.challenges_sent.build(params[:challenge_sent])
#              cs.to_user_id = u.id
#              if !cs.valid?
#                return HESResponder(cs.errors.full_messages, "ERROR") if !cs.errors.empty?
#              else
#                cs.save!
#              end
#            end
#            css.push(cs)
#          end
#        end
#        return HESResponder(css)
#      else


        ChallengeSent.transaction do
          challenge_sent.save!
        end
        if !challenge_sent.errors.empty?
          return HESResponder(challenge_sent.errors.full_messages, "ERROR")
        end
        return HESResponder(challenge_sent)


 #     end


    end
  end

  def update
    # TODO: make me
  end

  def destroy
    # TODO: make me
  end
end