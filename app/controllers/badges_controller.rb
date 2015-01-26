class BadgesController < ApplicationController
  authorize :index, :user_badges_earned, :show, :user
  authorize :create, :update, :destroy, :master

  def index
    if !params[:type].nil? && !params[:type].empty? && Badge::TYPE.values.include?(params[:type])
      badges = @promotion.badges.send(Badge::TYPE.index(params[:type]).to_s)
    else
      badges = @promotion.badges
    end
    return HESResponder(badges)
  end
  
  def user_badges_earned
    # maybe add a connected? method to the user to see if @target_user and @current_user are friends
    if @target_user.id != @current_user.id
      return HESResponder("You may not see the requested user's badges.", "ERROR")
    else
      year = (params[:year] || @target_user.promotion.current_date.year).to_i
      if !params[:type].nil? && !params[:type].empty? && Badge::TYPE.values.include?(params[:type])
        badges_earned = @target_user.badges_earned.where("user_badges.earned_year = #{year} AND badges.badge_type = '#{params[:type]}'")
      else
        badges_earned = @target_user.badges_earned.where(:earned_year => year)
      end
      return HESResponder(badges_earned)
    end
  end

  def show
    badge = Badge.find(params[:id]) rescue nil
    return HESResponder("Badge", "NOT_FOUND") if badge.nil?
    return HESResponder(badge)
  end

  def create
    badge = @promotion.badges.build(params[:badge])
    return HESResponder(badge.errors.full_messages, "ERROR") if !badge.valid?
    Badge.transaction do
      badge.save!
    end
    return HESResponder(badge)
  end

  def update
    badge = @promotion.badges.find(params[:id]) rescue nil
    return
    badge.assign_attributes(params[:badge])
    return HESResponder(badge.errors.full_messages, "ERROR") if !badge.valid?
    Badge.transaction do
      badge.save!
    end
    return HESResponder(badge)
  end

  def destroy
    badge = @promotion.badges.find(params[:id]) rescue nil
    return HESResponder("Badge", "NOT_FOUND") if badge.nil?
    Badge.transaction do
      badge.destroy
    end
    return HESResponder(badge)
  end



end
