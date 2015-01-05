class InvitesController < ApplicationController

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
    if !params[:event_id]
      return HESResponder("Must pass an event.", "ERROR")
    end
    # TODO: privacy needed here..
    event = Event.find(params[:event_id]) rescue nil
    if !event
      return HESResponder("Event", "NOT_FOUND")
    end
    return HESResponder(event.invites)
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
    invite = Invite.find(params[:id]) rescue nil
    return HESResponder("Invite", "NOT_FOUND") if !invite
    # TODO: privacy stuff here
    return HESResponder(invite)
    end
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
    # TODO: error when user has already been invited
    event = Event.find(params[:invite][:event_id]) rescue nil
    if !event
      return HESResponder("Event", "NOT_FOUND")
    end
    Invite.transaction do
      if params[:invite][:invited_user_id].nil? && !params[:invite][:invited_group_id].nil?
        group = Group.find(params[:invite][:invited_group_id]) rescue nil
        if !group.nil? && group.owner.id == @current_user.id
          invites = []
          group.users.each do |user|
            # TODO: not here though..
            # need to make sure when group users are referenced for various actions, such as here, that the group users are also still friends with @current_user
            # since they could be unfriended and still in the group, as of now..
            if @current_user.friends.include?(user)
              i = event.invites.build(:invited_user_id => user.id, :inviter_user_id => @current_user.id, :invited_group_id => invite[:invited_group_id])
              if !i.valid?
                return HESResponder(i.errors.full_messages, "ERROR")
              end
              i.save!
              invites.push(i)
              # do we need an error message if they aren't in the group anymore? shouldn't... should be taken care of soon as the unfriending occurs
              # there's actually a validation check on invite..
            end
          end
          return HESResponder(invites)
        else
          return HESResponder("Group",  "NOT_FOUND")
        end
      else
        i = event.invites.build(:invited_user_id => params[:invite][:invited_user_id], :inviter_user_id => @current_user.id)
        if !i.valid?
          return HESResponder(i.errors.full_messages, "ERROR")
        end
        i.save!
        return HESResponder(i)
      end
    end
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
  #    "entry_exercise_activities" : [{}]
  #   }
  def update
    @entry = @target_user.entries.find(params[:id])
    if @entry.user.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not edit this entry.", "DENIED")
    end
    Entry.transaction do
      entry_ex_activities = params[:entry].delete(:entry_exercise_activities)
      if !entry_ex_activities.nil?
        
        ids = entry_ex_activities.nil? ? [] : entry_ex_activities.map{|x| x[:id]}
        remove_activities = @entry.entry_exercise_activities.reject{|x| ids.include? x.id}

        remove_activities.each do |act|
          # Remove from array and delete from db
           @entry.entry_exercise_activities.delete(act).first.destroy
        end

        entry_ex_activities.each do |entry_ex_act|
          if entry_ex_act[:id]
            eea = @entry.entry_exercise_activities.detect{|x|x.id==entry_ex_act[:id].to_i}
            eea.update_attributes(scrub(entry_ex_act, EntryExerciseActivity))
          else
            @entry.entry_exercise_activities.create(scrub(entry_ex_act, EntryExerciseActivity))
          end
        end
      end

      entry_behaviors = params[:entry].delete(:entry_behaviors)
      if !entry_behaviors.nil?
        ids = entry_behaviors.nil? ? [] : entry_behaviors.map{|x| x.id}
        remove_behaviors = @entry.entry_behaviors.reject{|x| ids.include? x.id}

        remove_behaviors.each do |act|
          @entry.entry_behaviors.delete(act).first.destroy
        end

         entry_behaviors.each do |entry_behavior|
          if entry_behavior[:id]
            eb = @entry.entry_behaviors.detect{|x|x.id==entry_behavior[:id].to_i}
            eb.update_attributes(scrub(entry_behavior, EntryBehavior))
          else
            @entry.entry_behaviors.create(scrub(entry_behavior, EntryBehavior))
          end
        end
      end 

      @entry.save!
      @entry.update_attributes(scrub(params[:entry], Entry))
    end 
    return HESResponder(@entry)
  end
end