class BadgesController < ApplicationController
  authorize :index, :user_badges_earned, :show, :user
  authorize :create, :update, :destroy, :master

  def index
    if !params[:category].nil? && !params[:category].empty? && Badge::CATEGORY.values.include?(params[:category])
      badges = Badge.send(Badge::CATEGORY.index(params[:category]).to_s).where("minimum_program_length IS NULL OR minimum_program_length <= #{@promotion.program_length}")
    elsif !params[:category].nil? && params[:category] == 'rewards'
      if @current_user.master? && params[:promotion_id]
        @promotion = Promotion.find(params[:promotion_id])
      end
      badges = Badge.where("((minimum_program_length IS NULL OR minimum_program_length <= #{@promotion.program_length}) AND promotion_id = #{@promotion.id} AND category IN ('points_reward','patches_reward'))")
    else
      badges = Badge.where("((minimum_program_length IS NULL OR minimum_program_length <= #{@promotion.program_length}) AND category NOT IN ('points_reward','patches_reward'))")
    end
    badges = Badge.promotionize(badges, @promotion) unless @current_user && @current_user.master?
    return HESResponder(badges)
  end
  
  def user_badges_earned
    # maybe add a connected? method to the user to see if @target_user and @current_user are friends
    if @target_user.id != @current_user.id && (@target_user.companion && @target_user.companion.id != @current_user.id) && !@target_user.team.friends.collect{|f|f.id}.include?(@current_user.team.id)
      return HESResponder("You may not see the requested user's badges.", "ERROR")
    else
      if !params[:badge_id].nil? && params[:badge_id].is_i?
        # begin hack for speshul badge for pilot
        if params[:badge_id].to_i == 20 && !params[:earn].nil? && (params[:earn] == true || params[:earn] == 'true') && !params[:tip_id].nil? && params[:tip_id].to_i == 265
          badge = Badge.find(20) # speshul social media badge for pilot
          Badge.earn(@target_user, badge, @promotion.current_date)
          redirect_to "/#/shared_social" and return
        end
        # end speshul badge hack for pilot
        badges_earned = @target_user.badges_earned.where("badges.id = '#{params[:badge_id]}'")
      elsif !params[:category].nil? && !params[:category].empty? && Badge::CATEGORY.values.include?(params[:category])
        badges_earned = @target_user.badges_earned.where("badges.category = '#{Badge.sanitize(params[:category])}'")
      elsif !params[:category].nil? && params[:category] == 'rewards'
        badges_earned = @target_user.badges_earned.where("badges.category IN ('points_reward','patches_reward')")
      else
        badges_earned = @target_user.badges_earned.where("badges.category NOT IN ('points_reward','patches_reward')")
      end
      return HESResponder(Badge.promotionize(badges_earned, @current_user.promotion))
    end
  end

  def show
    badge = Badge.find(params[:id]) rescue nil
    return HESResponder("Badge", "NOT_FOUND") if badge.nil?
    return HESResponder(badge)
  end

  def create
    badge = Badge.create(params[:badge])
    return HESResponder(badge.errors.full_messages, "ERROR") if !badge.valid?
    Badge.transaction do
      badge.save!
    end
    return HESResponder(badge)
  end

  def update
    badge = Badge.find(params[:id]) rescue nil
    badge.assign_attributes(params[:badge])
    return HESResponder(badge.errors.full_messages, "ERROR") if !badge.valid?
    Badge.transaction do
      badge.save!
    end
    return HESResponder(badge)
  end

  def destroy
    badge = Badge.find(params[:id]) rescue nil
    return HESResponder("Badge", "NOT_FOUND") if badge.nil?
    Badge.transaction do
      badge.destroy
    end
    return HESResponder(badge)
  end

end
