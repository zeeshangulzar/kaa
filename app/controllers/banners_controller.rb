class BannersController < ApplicationController

  authorize :create, :update, :destroy, :location_coordinator
  authorize :index, :show, :public
  
  def index
    if !params[:location_id].nil?
      location = Location.find(params[:location_id]) rescue nil
      return HESResponder("Location", "NOT_FOUND") if !location
      return HESResponder(location.banners)
    else
      return HESResponder(@promotion.banners)
    end
  end

  def show
    if params[:id] == 'national'
      banners = @promotion.banners.where("location_id IS NULL") rescue nil
    else
      banners = Banner.find(params[:id]) rescue nil
    end
    return HESResponder("Banner", "NOT_FOUND") if !banners
    return HESResponder(banners)
  end

  def create
    banner = @promotion.banners.build(params[:banner])
    return HESResponder(banner.errors.full_messages, "ERROR") if !banner.valid?
    if (@current_user.location_coordinator? && @current_user.location_ids.include?(banner.location_id)) || (@current_user.coordinator_or_above? && @current_user.promotion_id == @promotion.id) || @current_user.master?
      Banner.transaction do
        banner.save!
      end
    else
      return HESResponder("Access denied.", "DENIED")
    end
    return HESResponder(banner)
  end

  def update
    banner = Banner.find(params[:id]) rescue nil
    return HESResponder("Banner", "NOT_FOUND") if !banner
    # can't change a banner's location or promotion, for now..
    params[:banner].delete(:location_id)
    params[:banner].delete(:promotion_id)
    if (@current_user.location_coordinator? && @current_user.location_ids.include?(banner.location_id)) || (@current_user.coordinator_or_above? && @current_user.promotion_id == banner.promotion_id) || @current_user.master?
      banner.assign_attributes(params[:banner])
      return HESResponder(banner.errors.full_messages, "ERROR") if !banner.valid?
      Banner.transaction do
        banner.save!
      end
    else
      return HESResponder("Access denied.", "DENIED")
    end
    return HESResponder(banner)
  end

  def destroy
    banner = banner.find(params[:id]) rescue nil
    return HESResponder("Banner", "NOT_FOUND") if !banner
    if (@current_user.coordinator_or_above? && @current_user.promotion_id == banner.promotion_id) || @current_user.master?
      Banner.transaction do
        banner.destroy
      end
    else
      return HESResponder("Access denied.", "DENIED")
    end
    return HESResponder(banner)
  end

end
