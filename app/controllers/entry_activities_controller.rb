class EntryActivitiesController < ApplicationController
  authorize :all, :user
  
  # Gets the list of entry_entry_activities
  #
  # @return [Array] of all entry_activities
  #
  # [URL] /entry_activities [GET]
  #  [200 OK] Successfully retrieved RecordingActivity Array object
  #   # Example response
  #   [{
  #    "id": 1,
  #    "entry_id" 1,
  #    "activity": 1,
  #    "value": 45,
  #    "activity": {
  #     "name": "Exercise",
  #     "content": "Exercising 30 minutes for 5 days a week is recommended"
  #     "sequence": 1
  #     "type_of_prompt": "text"
  #     "cap_value": 60,
  #     "cap_message": "Cannot record more than 60 minutes a day",
  #     "regex_validation": "^(\d){1,5}$"
  #    }
  #   }]
  def index
    unless params[:entry_id].nil?
      @entry_activities = Entry.find(params[:entry_id]).entry_activities
      return HESResponder(@entry_activities)
    else
      return HESResponder("Must pass entry id", "ERROR")
    end
  end

  # Gets a single entry_activity
  #
  # @example
  #  #GET /entry_activities/1
  #
  # @param [Integer] id of the entry_activity
  # @return [RecordingActivity] that matches the id
  #
  # [URL] /entry_activities/1 [GET]
  #  [200 OK] Successfully retrieved RecordingActivity object
  #   # Example response
  #   {
  #    "id": 1,
  #    "entry_id" 1,
  #    "activity": 1,
  #    "value": 45,
  #    "activity": {
  #     "name": "Exercise",
  #     "content": "Exercising 30 minutes for 5 days a week is recommended"
  #     "sequence": 1
  #     "type_of_prompt": "text"
  #     "cap_value": 60,
  #     "cap_message": "Cannot record more than 60 minutes a day",
  #     "regex_validation": "^(\d){1,5}$"
  #    }
  #   }
  def show
    @entry_activity = EntryRecordingActivity.find(params[:id])
    return HESResponder(@entry_activity)
  end

  # Creates a single entry_activity
  #
  # @example
  #  #POST /entry_activities/1
  #  {
  #    name: "Exercise",
  #    content: "Exercising 30 minutes for 5 days a week is recommended"
  #  }
  # @param [String] date of the entry that is be logged for
  # @return [RecordingActivity] that was just created
  #
  # [URL] /entry_activities [POST]
  #  [201 CREATED] Successfully created RecordingActivity object
  #   # Example response
  #   {
  #    "id": 1,
  #    "entry_id" 1,
  #    "activity": 1,
  #    "value": 45,
  #    "activity": {
  #     "name": "Exercise",
  #     "content": "Exercising 30 minutes for 5 days a week is recommended"
  #     "sequence": 1
  #     "type_of_prompt": "text"
  #     "cap_value": 60,
  #     "cap_message": "Cannot record more than 60 minutes a day",
  #     "regex_validation": "^(\d){1,5}$"
  #    }
  #   }
  def create
    # Lets us lazy create entries by just passing the date the entry is supposed to be logged
    if params[:entry_activity][:entry_id].nil?
      if params[:logged_on]
        entry = @target_user.entries.find_or_create_by_logged_on(params[:logged_on])
        params[:entry_activity][:entry_id] = entry.id
      else
        return HESResponder("Must pass logged on date for entry or entry id", "ERROR")
      end
    end
    
    @entry_activity = EntryRecordingActivity.create(params[:entry_activity])
    return HESResponder(@entry_activity)
  end

  # Updates a single entry_activity
  #
  # @example
  #  #PUT /entry_activities/1
  #  {
  #    name: "Walking",
  #    content: "Walking 10,000 steps a day is recommended"
  #  }
  #
  # @param [Integer] id of the entry_activity
  # @return [RecordingActivity] that was just updated
  #
  # [URL] /entry_activities [PUT]
  #  [202 ACCEPTED] Successfully updated RecordingActivity object
  #   # Example response
  #   {
  #    "id": 1,
  #    "entry_id" 1,
  #    "activity": 1,
  #    "value": 45,
  #    "activity": {
  #     "name": "Exercise",
  #     "content": "Exercising 30 minutes for 5 days a week is recommended"
  #     "sequence": 1
  #     "type_of_prompt": "text"
  #     "cap_value": 60,
  #     "cap_message": "Cannot record more than 60 minutes a day",
  #     "regex_validation": "^(\d){1,5}$"
  #    }
  #   }
  def update
    @entry_activity = EntryRecordingActivity.find(params[:id])
    @entry_activity.update_attributes(params[:entry_activity])

    return HESResponder(@entry_activity)
  end
  
  # Deletes a single entry_activity
  #
  # @example
  #  #DELETE /entry_activities/1
  #
  # @param [Integer] id of the team_invite
  # @return [team_invite] that was just deleted
  #
  # [URL] /invites/1?team_id=1 [DELETE]
  #  [200 OK] Successfully destroyed TeamInvite object
  #   # Example response
  #   {
  #    "id": 1,
  #    "entry_id" 1,
  #    "activity": 1,
  #    "value": 45,
  #    "activity": {
  #     "name": "Exercise",
  #     "content": "Exercising 30 minutes for 5 days a week is recommended"
  #     "sequence": 1
  #     "type_of_prompt": "text"
  #     "cap_value": 60,
  #     "cap_message": "Cannot record more than 60 minutes a day",
  #     "regex_validation": "^(\d){1,5}$"
  #    }
  #   }
  def destroy
    @entry_activity = EntryRecordingActivity.find(params[:id])
    @entry_activity.destroy

    return HESResponder(@entry_activity)
  end
end