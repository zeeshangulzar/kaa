class ResourcesController < ApplicationController

  authorize :create, :update, :destroy, :location_coordinator
  authorize :index, :show, :public
  
  def index
    if !params[:location_id].nil?
      location = Location.find(params[:location_id]) rescue nil
      return HESResponder("Location", "NOT_FOUND") if !location
      return HESResponder(location.resource)
    else
      return HESResponder(@promotion.resources)
    end
  end

  def show
    if params[:id] == 'national'
      resource = @promotion.resources.where("location_id IS NULL").first rescue nil
    else
      resource = Resource.find(params[:id]) rescue nil
    end
    return HESResponder("Resource", "NOT_FOUND") if !resource
    return HESResponder(resource)
  end

  def create
    resource = @promotion.resources.build(params[:resource])
    return HESResponder(resource.errors.full_messages, "ERROR") if !resource.valid?
    if (@current_user.location_coordinator? && @current_user.location_ids.include?(resource.location_id)) || (@current_user.sub_promotion_coordinator_or_above? && @current_user.promotion_id == @promotion.id) || @current_user.master?
      Resource.transaction do
        resource.save!
      end
    else
      return HESResponder("Access denied.", "DENIED")
    end
    return HESResponder(resource)
  end

  def update
    resource = Resource.find(params[:id]) rescue nil
    return HESResponder("Resource", "NOT_FOUND") if !resource
    params[:resource].delete!(:location_id)
    params[:resource].delete!(:promotion_id)
    if (@current_user.location_coordinator? && @current_user.location_ids.include?(resource.location_id)) || (@current_user.sub_promotion_coordinator_or_above? && @current_user.promotion_id == resource.promotion_id) || @current_user.master?
      resource.assign_attributes(params[:resource])
      return HESResponder(resource.errors.full_messages, "ERROR") if !resource.valid?
      Resource.transaction do
        resource.save!
      end
    else
      return HESResponder("Access denied.", "DENIED")
    end
    return HESResponder(resource)
  end

  def destroy
    resource = Resource.find(params[:id]) rescue nil
    return HESResponder("Resource", "NOT_FOUND") if !resource
    if (@current_user.sub_promotion_coordinator_or_above? && @current_user.promotion_id == resource.promotion_id) || @current_user.master?
      Resource.transaction do
        resource.destroy
      end
    else
      return HESResponder("Access denied.", "DENIED")
    end
    return HESResponder(resource)
  end

end
