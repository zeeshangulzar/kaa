class EventsController < ApplicationController

  authorize :all, :user
  
  def index
    return HESResponder2("You can't view other users' events.", "DENIED") if @target_user.id != @current_user.id && !@current_user.master?
    options = {
      :start => params[:start].nil? ? @promotion.current_time.beginning_of_month : params[:start].is_i? ? Time.at(params[:start].to_i).to_datetime : params[:start].to_datetime,
      :end => params[:end].nil? ? @promotion.current_time.end_of_month : params[:end].is_i? ? Time.at(params[:end.to_i]).to_datetime : params[:end].to_datetime
    }
    if !params[:status].nil?
      if Invite::STATUS.stringify_keys.keys.include?(params[:status])
        # ?status=[unresponded, maybe, attending, declined]
        e = @target_user.send(params[:status] + "_events", options)
      elsif params[:status].is_i? && Invite::STATUS.values.include?(params[:status].to_i)
        # ?status=[0, 1, 2, 3]
        e = @target_user.send(Invite::STATUS.index(params[:status].to_i).to_s + "_events", options)
      else
        return HESResponder2("No such status.", "ERROR")
      end
    else
      e = @target_user.subscribed_events(options)
    end
    return HESResponder2(e)
  end

  def show
    event = Event.find(params[:id]) rescue nil
    return HESResponder2("Event", "NOT_FOUND") if !event
    # TODO: privacy stuff here, probably quite similar to User::subscribed_events
    if event.is_user_subscribed?(@current_user) || @current_user.master?
      return HESResponder2(event)
    else
      return HESResponder2("You may not view other users' events.", "DENIED")
    end
  end

  def create
    invites = params[:event][:invites].nil? ? [] : params[:event].delete(:invites)
    event = @current_user.events.build(params[:event])
    if !event.valid?
      return HESResponder2(event.errors.full_messages, "ERROR")
    end
    Event.transaction do
      event.save!
      invites.each do |invite|
        if invite[:invited_user_id].nil? && !invite[:invited_group_id].nil?
          group = Group.find(invite[:invited_group_id]) rescue nil
          if !group.nil? && group.owner.id == @current_user.id
            group.users.each do |user|
              # TODO: not here though..
              # need to make sure when group users are referenced for various actions, such as here, that the group users are also still friends with @current_user
              # since they could be unfriended and still in the group, as of now..
              if @current_user.friends.include?(user)
                i = event.invites.build(:invited_user_id => user.id, :inviter_user_id => @current_user.id, :invited_group_id => invite[:invited_group_id])
                  if !i.valid?
                    return HESResponder2(i.errors.full_messages, "ERROR")
                  end
                  i.save!
                # do we need an error message if they aren't in the group anymore? shouldn't... should be taken care of soon as the unfriending occurs
                # there's actually a validation check on invite..
              end
            end
          else
            return HESResponder2("Group",  "NOT_FOUND")
          end
        else
          i = event.invites.build(:invited_user_id => invite[:invited_user_id], :inviter_user_id => @current_user.id)
          if !i.valid?
            return HESResponder2(i.errors.full_messages, "ERROR")
          end
          i.save!
        end
      end
    end
    return HESResponder2(event)
  end

  def update
    event = Event.find(params[:id]) rescue nil
    return HESResponder2("Event", "NOT_FOUND") if !event
    if !params[:event].nil? && !params[:event][:invites].nil?
      params[:event].delete(:invites)
    end
    Event.transaction do
      event.update_attributes(params[:event])
      if !event.valid?
        return HESResponder2(event.errors.full_messages, "ERROR")
      end
      event.save!
    end
    return HESResponder2(event)
  end

  def destroy
    event = Event.find(params[:id]) rescue nil
    if !event
      return HESResponder2("Event", "NOT_FOUND")
    elsif (event.user_id == @current_user.id || @current_user.master?) && event.destroy
      return HESResponder2(event)
    else
      return HESResponder2("Error deleting.", "ERROR")
    end
  end

end