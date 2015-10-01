# Controller for handling all location type requests
class LocationsController < ApplicationController

  respond_to :json
  
  authorize :index, :show, :public
  authorize :update, :create, :destroy, :upload, :master

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.locations : Location
  end
  private :set_sandbox

  def index
    if !params[:location_id].nil?
      location = @SB.find(params[:location_id]) rescue nil
      return HESResponder("Location", "NOT_FOUND") if !location
      locations = location.locations
    else
      locations = @promotion.nested_locations
    end
    return HESResponder(locations)
  end

  def show
    location = @SB.find(params[:id])
    return HESResponder(location)
  end

  def create
    location = nil
    Location.transaction do
      location = @SB.create(params[:location])
    end
    return HESResponder(location.errors.full_messages, "ERROR") if !location || !location.valid?
    return HESResponder(location)
  end

  def update
    location = @SB.find(params[:id])
    Location.transaction do
      location.update_attributes(params[:location])
    end
    return HESResponder(location)
  end

  def destroy
    location = @SB.find(params[:id])
    if location.destroy
      return HESResponder(location)
    else
      return HESResponder("Cannot destroy a location that has models assigned to it", "ERROR")
    end
  end

  # TODO: this doesn't work...
  def upload
    Location.upload_list(@promotion, params[:promotion_location][:list])
    locations = @locationable.locations
    return HESResponder(locations)
  end
end
