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
    event = Event.find(params[:event_id]) rescue nil
    return HESResponder("Event", "NOT_FOUND") if !event
    if !@current_user.master? && !event.is_user_subscribed?(@current_user)
      return HESResponder("You may not view this event.", "DENIED")
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
    if !@current_user.master? && !invite.event.is_user_subscribed?(@current_user)
      return HESResponder("You may not view this event.", "DENIED")
    end
    return HESResponder(invite)
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
    i = nil
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
        if event.privacy == Event::PRIVACY[:all_friends] || event.privacy == Event::PRIVACY[:location] || @current_user.id == event.user_id 
          i = event.invites.build(:invited_user_id => params[:invite][:invited_user_id], :inviter_user_id => event.user_id)
        else
          return HESResponder("User not allowed to create invite for event", "ERROR")
        end
        if !i.valid?
          return HESResponder(i.errors.full_messages, "ERROR")
        end
        i.save!
      end
    end
    return HESResponder(i)
  end
  
  def update
    invite = Invite.find(params[:id]) rescue nil
    if !invite
      return HESResponder("Invite", "NOT_FOUND")
    end

    params[:invite] = params[:invite].delete_if{|k,v|k != 'status'}

    Invite.transaction do
      invite.update_attributes(params[:invite])
      if !invite.valid?
        return HESResponder(invite.errors.full_messages, "ERROR")
      end
      invite.save!
    end
    return HESResponder(invite)
  end

end
