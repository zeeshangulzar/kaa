class ResellersController < ApplicationController
  respond_to :json

  authorize :all, :master

  # Get all resellers for a reseller
  #
  # @url [GET] /resellers
  # @authorize
  # @return [Array<Reseller>] Array of resellers
  #
  # [URL] /resellers/:id [GET]
  #  [200 OK] Successfully retrieved Reseller
  #   # Example response
  #   [{
  #    "id": 1,
  #    "name": "HES",
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "http://api.passport.com/resellers/1"
  #   }]
  def index
    resellers = Reseller.all
    return HESResponder(@resellers.to_json(:include => [:organizations, :promotions]))
  end

  # Get a reseller
  #
  # @url [GET] /resellers/1
  #
  # @param [Integer] id The id of the reseller
  # @return [Reseller] Reseller that matches the id
  #
  # [URL] /resellers/:id [GET]
  #  [200 OK] Successfully retrieved Reseller
  #   # Example response
  #   {
  #    "id": 1,
  #    "name": "HES",
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "/resellers/1"
  #   }
  def show
    reseller = Reseller.find(params[:id])
    if !reseller
      return HESResponder("Reseller doesn't exist.", "NOT_FOUND")
    end
    return HESResponder(reseller)
  end

  # Create a reseller
  #
  # @url POST /resellers/1
  #
  # @param [String] name The name of the reseller
  # @return [Reseller] Reseller that matches the id
  #
  # [URL] /resellers [POST]
  #  [201 CREATED] Successfully created a Reseller
  #   # Example response
  #   {
  #    "id": 1,
  #    "name": "HES",
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "/resellers/1"
  #   }
  def create
    reseller = Reseller.create(params[:reseller])
    if !reseller.valid?
      return HESResponder(reseller.errors.full_messages, "ERROR")
    else
      return HESResponder(reseller)
    end
  end

  # Update a reseller
  #
  # @url PUT /resellers/1
  # @authorize Master
  # @param [Integer] id The id of the reseller
  # @param [String] name The name of the reseller
  # @return [Reseller] Reseller that matches the id
  #
  # [URL] /resellers/:id [PUT]
  #  [202 ACCEPTED] Successfully updated Reseller
  #   # Example response
  #   {
  #    "id": 1,
  #    "name": "HES",
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "/resellers/1"
  #   }
  def update
    reseller = Reseller.find(params[:id])
    if !reseller
      return HESResponder("Reseller doesn't exist.", "NOT_FOUND")
    else
      if !reseller.update_attributes(params[:reseller])
        return HESResponder(reseller.errors.full_messages, "ERROR")
      else
        return HESResponder(reseller)
      end
    end
  end

  # Deletes a reseller
  #
  # @url DELETE /resellers/1
  #
  # @param [Integer] id The id of the reseller
  # @return [Reseller] Reseller that matches the id
  #
  # [URL] /resellers/:id [DELETE]
  #  [200 OK] Successfully deleted Reseller
  #   # Example response
  #   {
  #    "id": 1,
  #    "name": "HES",
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "/resellers/1"
  #   }
  def destroy
    reseller = Reseller.find(params[:id])
    if !reseller
      return HESResponder("Reseller doesn't exist.", "NOT_FOUND")
    elsif reseller.destroy
      return HESResponder(reseller)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end
end
