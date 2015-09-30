# Controller for handling all location type requests
class LocationsController < ApplicationController

  respond_to :json
  
  authorize :index, :show, :public
  authorize :update, :create, :destroy, :upload, :master

  def index
    if !params[:location_id].nil?
      location = @promotion.locations.find(params[:location_id]) rescue nil
      return HESResponder("Location", "NOT_FOUND") if !location
      locations = location.locations
    else
      locations = @promotion.nested_locations
    end
    return HESResponder(locations)
  end

  def show
    @location = @promotion.locations.find(params[:id])
    return HESResponder(@location)
  end

  def create
    Location.transaction do
      @location = @promotion.locations.create(params[:location])
      return HESResponder(@location.errors.full_messages, "ERROR") if !@location.valid?
    end
    return HESResponder(@location)
  end

  def update
    @location = @promotion.locations.find(params[:id])
    Location.transaction do
      @location.update_attributes(params[:location])
    end
    return HESResponder(@location)
  end

  def destroy
    @location = @promotion.locations.find(params[:id])
    if @location.destroy
      return HESResponder(@location)
    else
      return HESResponder("Cannot destroy a location that has models assigned to it", "ERROR")
    end
  end

  def upload
    Location.upload_list(@promotion, params[:promotion_location][:list])
    @locations = @locationable.locations
    return HESResponder(@locations)
  end
end
