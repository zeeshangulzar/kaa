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
    event = Event.find(params[:invite][:event_id]) rescue nil
    if !event
      return HESResponder("Event", "NOT_FOUND")
    end

    already_invited_user_ids = event.invites.collect{|invite|invite.invited_user_id}

    user_group_ids = @current_user.groups.collect{|group|group.id}
    user_friend_ids = @current_user.friends.collect{|friend|friend.id}

    # make sure all posted group ids are valid
    invited_group_ids = params[:invite][:invited_group_id].nil? ? [] : params[:invite][:invited_group_id].is_a?(Array) ? params[:invite][:invited_group_id] : [params[:invite][:invited_group_id]]
    bad_group_ids = invited_group_ids.reject{|id|user_group_ids.include?(id)}
    return HESResponder("Invalid group id(s).", "ERROR") if !bad_group_ids.empty?

    # make sure all posted user ids are valid
    invited_user_ids = params[:invite][:invited_user_id].nil? ? [] : params[:invite][:invited_user_id].is_a?(Array) ? params[:invite][:invited_user_id] : [params[:invite][:invited_user_id]]
    bad_user_ids = invited_user_ids.reject{|id|user_friend_ids.include?(id)}
    return HESResponder("Invalid friend id(s).", "ERROR") if !bad_user_ids.empty?
    
    # add group users to invited users
    invited_group_ids.each{|id|
      Group.find(id).users.each{|user|
        invited_user_ids.push(user.id) unless invited_user_ids.include?(user.id)
      }
    }

    # filter out users that already have invites
    invited_user_ids.reject!{|id|already_invited_user_ids.include?(id)}
    
    # build the invites
    i = nil
    invites = []
    Invite.transaction do
      invited_user_ids.each{|id|
        i = event.invites.build(:invited_user_id => id, :inviter_user_id => @current_user.id)
        if !i.valid?
          return HESResponder(i.errors.full_messages, "ERROR")
        end
        i.save!
        invites.push(i)
      }
    end
    return HESResponder(invites)
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
