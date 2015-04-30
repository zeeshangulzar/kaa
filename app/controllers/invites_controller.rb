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
    event_id = params[:invite][:event_id].nil? ? params[:event_id] : params[:invite][:event_id]
    event = Event.find(event_id) rescue nil
    if !event
      return HESResponder("Event", "NOT_FOUND")
    end

    already_invited_user_ids = event.invites.collect{|invite|invite.invited_user_id}

    if @current_user.id != event.user.id
      # catch users making their own invites (in the case of PRIVACY == all_friends & coordinator events
      return HESResponder("User not invited to this event.", "ERROR") if !event.is_user_subscribed?(@current_user) # this line is important, otherwise the user could invite himself to anything..
      if already_invited_user_ids.include?(@current_user.id)
        # maybe we should do an update on the invite
        return HESResponder(event.invites.where(:invited_user_id => @current_user.id))
      else
        invite = event.invites.build(:invited_user_id => @current_user.id, :inviter_user_id => event.user.id, :status => params[:invite][:status])
        if !invite.valid?
          return HESResponder(invite.errors.full_messages, "ERROR")
        end
        Invite.transaction do
          invite.save!
        end
        invite.event.send_invited_notification(invite.user)
        return HESResponder(invite)
      end
    end

    user_group_ids = event.user.groups.collect{|group|group.id}
    user_friend_ids = event.user.friends.collect{|friend|friend.id}

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
        i = event.invites.build(:invited_user_id => id, :inviter_user_id => event.user.id)
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
