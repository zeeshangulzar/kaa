class PromotionsController < ApplicationController
  authorize :index, :create, :update, :destroy, :master

  authorize :show, :current, :top_location_stats, :verify_users_for_achievements, :public
  authorize :index, :poster
  authorize :create, :update, :destroy, :master

  def index
    promotions = params[:organization_id] ? Organization.find(params[:organization_id]).promotions : params[:reseller_id] ? Reseller.find(params[:reseller_id]).promotions : Promotion.all
    return HESResponder(promotions)
  end

  # Get a promotion
  #
  # @url [GET] /promotions/1
  # @param [Integer] id The id of the promotion
  # @return [Promotion] Promotion that matches the id
  #
  # [URL] /promotions/:id [GET]
  #  [200 OK] Successfully retrieved Promotion
  def show
    promotion = (params[:id] == 'current') ? @promotion : Promotion.find(params[:id]) rescue nil
    if !promotion
      return HESResponder("Promotion", "NOT_FOUND")
    end
    return HESResponder(promotion)
  end

  def current
    #@promotion.logo = @promotion.logo_for_user(@current_user) if @current_user
    #@promotion.resources_title = @promotion.resources_title_for_user(@current_user) if @current_user
    if @current_user && @current_user.user?
      params[:id] = @promotion.id
      return HESCachedResponder('promotions', @promotion)
    end
    return HESResponder(@promotion)
  end

  def create
    Promotion.transaction do
      promotion = Promotion.create(params[:promotion])
    end
    if !promotion.valid?
      return HESResponder(promotion.errors.full_messages, "ERROR")
    end
    return HESResponder(promotion)
  end
  
  def update
    promotion = Promotion.find(params[:id])
    if !promotion
      return HESResponder("Promotion", "NOT_FOUND")
    else
      Promotion.transaction do
        promotion.update_attributes(params[:promotion])
      end
      if !promotion.valid?
        return HESResponder(promotion.errors.full_messages, "ERROR")
      else
        return HESResponder(promotion)
      end
    end
  end
  
  def destroy
    promotion = Promotion.find(params[:id]) rescue nil
    if !promotion
      return HESResponder("Promotion", "NOT_FOUND")
    elsif promotion.destroy
      return HESResponder(promotion)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

  def top_location_stats
    locations = @promotion.nested_locations
    locations.each_with_index{|location, index|
      locations[index][:user_count] = User.where(:location_id => [location['id']] + location[:locations].collect{|l|l['id']}).count
      locations[index].delete(:locations)
    }
    render :json => {:data => locations} and return
  end

  def verify_users_for_achievements
    Profile.do_nuid_verification
    render :text=>'OK',:layout=>nil
  end

end
