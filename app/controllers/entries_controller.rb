class EntriesController < ApplicationController

  authorize :all, :user
  
  # Gets the list of entries for an team instance
  #
  # @return [Array] of all entries
  #
  # [URL] /entries [GET]
  #  [200 OK] Successfully retrieved Entry Array object
  #   # Example response
  #   [{
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_logged": true
  #    "recorded_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #   }]
  def index
    @entries = @user.entries.available.to_a
    return HESResponder(@entries)
  end

  # Gets a single entry for a team
  #
  # @example
  #  #GET /entries/1
  #
  # @param [Integer] id of the entry
  # @return [Entry] that matches the id
  #
  # [URL] /entries/1 [GET]
  #  [200 OK] Successfully retrieved Entry object
  #   # Example response
  #   {
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_logged": true
  #    "recorded_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #   }
  def show
    @entry = @user.entries.find(params[:id])
    return HESResponder(@entry)
  end

  # Creates a single entry
  #
  # @example
  #  #POST /entries/1
  #  {
  #    exercise_minutes: 45,
  #    notes: "Eliptical machine while reading Fitness magazine"
  #  }
  # @return [Entry] that was just created
  #
  # [URL] /entries [POST]
  #  [201 CREATED] Successfully created Entry object
  #   # Example response
  #   {
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_logged": true
  #    "recorded_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #   }
  def create
    Entry.transaction do
      ex_activities = params[:entry].delete(:entry_exercise_activities) || []
      activities = params[:entry].delete(:entry_activities) || []
      @entry = @user.entries.build(params[:entry])
      @entry.save!

      #create exercise activites
      ex_activities.each do |hash|
        @entry.entry_exercise_activities.build(scrub(hash, EntryExerciseActivity))
      end

      #TODO: Test entry activities
      activities do |hash|
        @entry.entry_activities.build(scrub(hash, EntryActvitity))
      end

      @entry.save!
    end
    return HESResponder(@entry)
  end

  # Updates a single entry
  #
  # @example
  #  #PUT /entries/1
  #  {
  #    exercise_minutes: 45,
  #    notes: "Eliptical machine while reading Fitness magazine"
  #  }
  #
  # @param [Integer] id of the entry
  # @return [Entry] that was just updated
  #
  # [URL] /entries [PUT]
  #  [202 ACCEPTED] Successfully updated Entry object
  #   # Example response
  #   {
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_recorded": true
  #    "recorded_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #    "entry_activities" : [{}]
  #    "entry_exercise_activites" : [{}]
  #   }
  def update
    @entry = @user.entries.find(params[:id])
    Entry.transaction do
      params[:entry].delete(:entry_exercise_activities).each do |hash|
        if hash[:id]
          #update
          eea = @entry.entry_exercise_activities.find(hash[:id])
          eea.update_attributes(scrub(hash, EntryExerciseActivity))

        else
          #create
          @entry.entry_exercise_activities.build(scrub(hash, EntryExerciseActivity))
        end
      end

       params[:entry].delete(:entry_activities).each do |hash|
        if hash[:id]
          #update
          eea = @entry.entry_activities.find(hash[:id])
          eea.update_attributes(scrub(hash, EntryActivity))

        else
          #create
          @entry.entry_activities.build(scrub(hash, EntryActivity))
        end
      end

      @entry.update_attributes(scrub(params[:entry], Entry))
    end 
    return HESResponder(@entry)
  end
end