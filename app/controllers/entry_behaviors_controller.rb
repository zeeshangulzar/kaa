class EntryBehaviorsController < ApplicationController
  authorize :all, :user
  
  # Gets the list of entry_behaviors
  #
  # @return [Array] of all entry_behaviors
  #
  # [URL] /entry_behaviors [GET]
  #  [200 OK] Successfully retrieved EntryBehavior Array object
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
      @entry_behaviors = Entry.find(params[:entry_id]).entry_behaviors
      return HESResponder(@entry_behaviors)
    else
      return HESResponder("Must pass entry id", "ERROR")
    end
  end

  # Gets a single entry_behavior
  #
  # @example
  #  #GET /entry_behaviors/1
  #
  # @param [Integer] id of the entry_behavior
  # @return [EntryBehavior] that matches the id
  #
  # [URL] /entry_behaviors/1 [GET]
  #  [200 OK] Successfully retrieved EntryBehavior object
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
    @entry_behavior = EntryBehavior.find(params[:id])
    return HESResponder(@entry_behavior)
  end

  # Creates a single entry_behavior
  #
  # @example
  #  #POST /entry_behaviors/1
  #  {
  #    name: "Exercise",
  #    content: "Exercising 30 minutes for 5 days a week is recommended"
  #  }
  # @param [String] date of the entry that is be logged for
  # @return [EntryBehavior] that was just created
  #
  # [URL] /entry_behaviors [POST]
  #  [201 CREATED] Successfully created EntryBehavior object
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
    if params[:entry_behavior][:entry_id].nil?
      if params[:logged_on]
        entry = @target_user.entries.find_or_create_by_logged_on(params[:logged_on])
        params[:entry_behavior][:entry_id] = entry.id
      else
        return HESResponder("Must pass logged on date for entry or entry id", "ERROR")
      end
    end
    
    @entry_behavior = EntryBehavior.create(params[:entry_behavior])
    return HESResponder(@entry_behavior)
  end

  # Updates a single entry_behavior
  #
  # @example
  #  #PUT /entry_behaviors/1
  #  {
  #    name: "Walking",
  #    content: "Walking 10,000 steps a day is recommended"
  #  }
  #
  # @param [Integer] id of the entry_behavior
  # @return [EntryBehavior] that was just updated
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
    @entry_behavior = EntryRecordingActivity.find(params[:id])
    @entry_behavior.update_attributes(params[:entry_behavior])
    return HESResponder(@entry_behavior)
  end
  
  # Deletes a single entry_behavior
  #
  # @example
  #  #DELETE /entry_behaviors/1
  #
  # @param [Integer] id of the entry_behavior
  # @return [entry_behavior] that was just deleted
  #
  # [URL] /entry_behaviors/1 [DELETE]
  #  [200 OK] Successfully destroyed EntryBehavior object
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
    @entry_behavior = EntryBehavior.find(params[:id])
    @entry_behavior.destroy
    return HESResponder(@entry_behavior)
  end
end