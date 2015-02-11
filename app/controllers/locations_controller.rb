# Controller for handling all location type requests
class LocationsController < ApplicationController

  respond_to :json
  
  authorize :index, :show, :public
  authorize :update, :create, :destroy, :upload, :master

  # Gets the list of locations for a locationable instance
  #
  # @url [GET] /promotions/1/locations
  # @authorize Public
  # @return [Array] of all locations
  #
  # [URL] /:locationable_type/:locationable_id/locations [GET]
  #  [200 OK] Successfully retrieved Location object
  #   # Example response
  #   [{
  #     "name": "New York City",
  #     "sequence": 1,
  #     "depth": 1,
  #     "parent_location_id": null,
  #     "root_location_id": null,
  #     "locationable_type": "Promotion",
  #     "locationable_id": 1,
  #     "locations": [...],
  #     "created_at": "2014-03-28T13:26:42-04:00",
  #     "updated_at": "2014-03-28T13:26:42-04:00",
  #     "url": "http://api.hesapps.com/locations/1"
  #   }]
  def index
    if !params[:location_id].nil?
      location = Location.find(params[:location_id]) rescue nil
      return HESResponder("Location", "NOT_FOUND") if !location
      locations = location.locations
    else
      locations = @promotion.nested_locations.as_json(:include => :locations)
    end

    return HESResponder(locations)
  end

  # Gets a single location from a locationable instance
  #
  # @url [GET] /promotions/1/locations
  # @authorize Public
  # @param [Integer] id of the location
  # @return [Location] that matches the id
  #
  # [URL] /locations/:id [GET]
  #  [200 OK] Successfully retrieved Location object
  #   # Example response
  #   {
  #     "name": "New York City",
  #     "sequence": 1,
  #     "depth": 1,
  #     "parent_location_id": null,
  #     "root_location_id": null,
  #     "locationable_type": "Promotion",
  #     "locationable_id": 1,
  #     "locations": [...],
  #     "created_at": "2014-03-28T13:26:42-04:00",
  #     "updated_at": "2014-03-28T13:26:42-04:00",
  #     "url": "http://api.hesapps.com/locations/1"
  #   }
  def show
    @location = Location.find(params[:id])
    return HESResponder(@location)
  end

  # Creates a single location for a locationable instance
  #
  # @url [POST] /promotions/1/locations
  # @authorize Master
  # @param [Integer] locationable_id The locationable id of the owner of the location
  # @param [String] locationable_type The locationable type of the owner of the location
  # @param [String] name The name of the location
  # @param [Integer] sequence The sequence of the location
  # @param [Integer] depth The nested level of the location
  # @param [Integer] parent_location_id The id of the location that owns this location. For example, Midland would have Michigan has parent location.
  # @param [Integer] root_location_id The id of the location that is the top location. For example, Midland would have Michigan has parent location, while Unitied States would be the root location.
  # @return [Location] Location that matches the id
  #
  # [URL] /:locationable_type/:locationable_id/locations [POST]
  #  [201 CREATED] Successfully created Location object
  #   # Example response
  #   {
  #     "name": "New York City",
  #     "sequence": 1,
  #     "depth": 1,
  #     "parent_location_id": null,
  #     "root_location_id": null,
  #     "locationable_type": "Promotion",
  #     "locationable_id": 1,
  #     "locations": [...],
  #     "created_at": "2014-03-28T13:26:42-04:00",
  #     "updated_at": "2014-03-28T13:26:42-04:00",
  #     "url": "http://api.hesapps.com/locations/1"
  #   }
  def create
    Location.transaction do
      @location = @promotion.locations.create(params[:location])
      return HESResponder(@location.errors.full_messages, "ERROR") if !@location.valid?
    end
    return HESResponder(@location)
  end


  # Updates a single location for a locationable instance
  #
  # @url [PUT] /locations/1
  # @authorize Master
  # @param [Integer] id The id of the location
  # @param [String] name The name of the location
  # @param [Integer] sequence The sequence of the location
  # @param [Integer] depth The nested level of the location
  # @param [Integer] parent_location_id The id of the location that owns this location. For example, Midland would have Michigan has parent location.
  # @param [Integer] root_location_id The id of the location that is the top location. For example, Midland would have Michigan has parent location, while Unitied States would be the root location.
  # @return [Location] Location that matches the id
  #
  # [URL] /locations/:id [PUT]
  #  [202 ACCEPTED] Successfully updated Location object
  #   # Example response
  #   {
  #     "name": "New York City",
  #     "sequence": 1,
  #     "depth": 1,
  #     "parent_location_id": null,
  #     "root_location_id": null,
  #     "locationable_type": "Promotion",
  #     "locationable_id": 1,
  #     "locations": [...],
  #     "created_at": "2014-03-28T13:26:42-04:00",
  #     "updated_at": "2014-03-28T13:26:42-04:00",
  #     "url": "http://api.hesapps.com/locations/1"
  #   }
  def update
    @location = Location.find(params[:id])
    Location.transaction do
      @location.update_attributes(params[:location])
    end
    return HESResponder(@location)
  end

  # Deletes a single location from a locationable instance
  #
  # @url [DELETE] /locations/:id
  # @authorize Master
  # @param [Integer] id The id of the location
  # @return [Location] Location that matches the id
  #
  # [URL] /locations/:id [DELETE]
  #  [200 OK] Successfully retrieved Location object
  #   # Example response
  #   {
  #     "name": "New York City",
  #     "sequence": 1,
  #     "depth": 1,
  #     "parent_location_id": null,
  #     "root_location_id": null,
  #     "locationable_type": "Promotion",
  #     "locationable_id": 1,
  #     "locations": [...],
  #     "created_at": "2014-03-28T13:26:42-04:00",
  #     "updated_at": "2014-03-28T13:26:42-04:00",
  #     "url": "http://api.hesapps.com/locations/1"
  #   }
  def destroy
    @location = Location.find(params[:id])
    if @location.destroy
      return HESResponder(@location)
    else
      return HESResponder("Cannot destroy a location that has models assigned to it", "ERROR")
    end
  end

  # Uploads a file and creates location list from it
  #
  # @url [POST] /promotions/1/locations/upload
  # @authorize Master
  # @param [String] list Path to CSV file containing list of locations
  # @return [Array<Location>] Array of created locations
  #
  # [URL] /:locationable_type/:locationable_id/locations/upload [POST]
  #  [200 OK] Successfully created all locations
  #   # Example Response
  #   [{
  #     "name": "New York City",
  #     "sequence": 1,
  #     "depth": 1,
  #     "parent_location_id": null,
  #     "root_location_id": null,
  #     "locationable_type": "Promotion",
  #     "locationable_id": 1,
  #     "locations": [...],
  #     "created_at": "2014-03-28T13:26:42-04:00",
  #     "updated_at": "2014-03-28T13:26:42-04:00",
  #     "url": "http://api.hesapps.com/locations/1"
  #   }]
  def upload
    Location.upload_list(@promotion, params[:promotion_location][:list])
    @locations = @locationable.locations
    return HESResponder(@locations)
  end
end
