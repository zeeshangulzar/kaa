class BehaviorsController < ApplicationController
  authorize :all, :master
  authorize :index, :user
  
  # Gets the list of activities
  #
  # @return [Array] of all activities
  #
  # [URL] /activities [GET]
  #  [200 OK] Successfully retrieved Activity Array object
  #   # Example response
  #   [{
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_logged": true
  #    "logged_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #   }]
  def index
    @activities = !@promotion.nil? ? @promotion.activities : Activity.all
    return HESResponder(@activities)
  end

  # Gets a single activity
  #
  # @example
  #  #GET /activities/1
  #
  # @param [Integer] id of the activity
  # @return [Activity] that matches the id
  #
  # [URL] /activities/1 [GET]
  #  [200 OK] Successfully retrieved Activity object
  #   # Example response
  #   {
  #    "id": 1,
  #    "name": "Exercise",
  #    "content": "Exercising 30 minutes for 5 days a week is recommended"
  #    "sequence": 1
  #    "type_of_prompt": "text"
  #    "cap_value": 60,
  #    "cap_message": "Cannot record more than 60 minutes a day",
  #    "regex_validation": "^(\d){1,5}$"
  #   }
  def show
    @activity = Activity.find(params[:id])
    return HESResponder(@activity)
  end

  # Creates a single activity
  #
  # @example
  #  #POST /activities/1
  #  {
  #    name: "Exercise",
  #    content: "Exercising 30 minutes for 5 days a week is recommended"
  #  }
  # @return [Activity] that was just created
  #
  # [URL] /activities [POST]
  #  [201 CREATED] Successfully created Activity object
  #   # Example response
  #   {
  #    "id": 1,
  #    "name": "Exercise",
  #    "content": "Exercising 30 minutes for 5 days a week is recommended"
  #    "sequence": 1
  #    "type_of_prompt": "text"
  #    "cap_value": 60,
  #    "cap_message": "Cannot record more than 60 minutes a day",
  #    "regex_validation": "^(\d){1,5}$"
  #   }
  def create
    Activity.transaction do
      @activity = Activity.create(params[:_activity])
    end
    return HESResponder(@activity)
  end

  # Updates a single activity
  #
  # @example
  #  #PUT /activities/1
  #  {
  #    name: "Walking",
  #    content: "Walking 10,000 steps a day is recommended"
  #  }
  #
  # @param [Integer] id of the activity
  # @return [Activity] that was just updated
  #
  # [URL] /activities [PUT]
  #  [202 ACCEPTED] Successfully updated Activity object
  #   # Example response
  #   {
  #    "id": 1,
  #    "name": "Exercise",
  #    "content": "Exercising 30 minutes for 5 days a week is recommended"
  #    "sequence": 1
  #    "type_of_prompt": "text"
  #    "cap_value": 60,
  #    "cap_message": "Cannot record more than 60 minutes a day",
  #    "regex_validation": "^(\d){1,5}$"
  #   }
  def update
    @activity = Activity.find(params[:id])
    Activity.transaction do
      @activity.update_attributes(params[:_activity])
    end
    return HESResponder(@activity)
  end
  
  # Deletes a single _activity
  #
  # @example
  #  #DELETE /activities/1
  #
  # @param [Integer] id of the team_invite
  # @return [team_invite] that was just deleted
  #
  # [URL] /invites/1?team_id=1 [DELETE]
  #  [200 OK] Successfully destroyed TeamInvite object
  #   # Example response
  #   {
  #    "id": 1,
  #    "name": "Exercise",
  #    "content": "Exercising 30 minutes for 5 days a week is recommended"
  #    "sequence": 1
  #    "type_of_prompt": "text"
  #    "cap_value": 60,
  #    "cap_message": "Cannot record more than 60 minutes a day",
  #    "regex_validation": "^(\d){1,5}$"
  #   }
  def destroy
    @activity = Activity.find(params[:id])
    Activity.transaction do
      @activity.destroy
    end
    return HESResponder(@activity)
  end
end