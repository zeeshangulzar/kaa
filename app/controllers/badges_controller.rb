class BadgesController < ApplicationController
  authorize :index, :user

  def index
    # maybe add a connected? method to the user to see if @target_user and @current_user are friends
    if @target_user != @current_user
      return HESResponder("You may not see the requested user's badges.", "ERROR")
    else
      year = (params[:year] || @target_user.promotion.current_date.year).to_i
      badges_earned = @target_user.badges.where(:earned_year=>year)
      badges_earned_keys = badges_earned.collect &:badge_key

      badges_possible_keys = Badge.possible(@target_user.promotion,year)
      badges_not_earned_keys = badges_possible_keys - badges_earned_keys
      badges_not_earned = badges_not_earned_keys.collect{|badge_key| Badge.new(:user_id => @target_user.id, :badge_key => badge_key)}

      return HESResponder(badges_earned.concat(badges_not_earned))
    end
  end
end
