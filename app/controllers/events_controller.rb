class EventsController < ApplicationController

  authorize :all, :user
  
  def index
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
        return HESResponder("No such status.", "ERROR")
      end
    else
      e = @target_user.subscribed_events(options)
    end
    return HESResponder(e)
  end

  def show
    event = Event.find(params[:id]) rescue nil
    return HESResponder("Event", "NOT_FOUND") if !event
    # TODO: privacy stuff here, probably quite similar to User::subscribed_events
    if event.is_user_subscribed?(@current_user) || @current_user.master?
      return HESResponder(event)
    else
      return HESResponder("You may not view other users' events.", "DENIED")
    end
  end

  def create
    invites = params[:event][:invites].nil? ? [] : params[:event].delete(:invites)
    event = @current_user.events.build(params[:event])
    if !event.valid?
      return HESResponder(event.errors.full_messages, "ERROR")
    end
    Event.transaction do
      event.save!
      invites.each do |invite|
        i = event.invites.build(:invited_user_id => invite[:invited_user_id], :inviter_user_id => @current_user.id)
        if !i.valid?
          return HESResponder(i.errors.full_messages, "ERROR")
        end
        i.save!
      end
    end
    return HESResponder(event)
  end

  def update
    event = Event.find(params[:id]) rescue nil
    return HESResponder("Event", "NOT_FOUND") if !event
    if !params[:event].nil? && !params[:event][:invites].nil?
      params[:event].delete(:invites)
    end
    Event.transaction do
      event.update_attributes(params[:event])
      if !event.valid?
        return HESResponder(event.errors.full_messages, "ERROR")
      end
      event.save!
    end
    return HESResponder(event)
  end

  def destroy
    event = Event.find(params[:id]) rescue nil
    if !event
      return HESResponder("Event", "NOT_FOUND")
    elsif (event.user_id == @current_user.id || @current_user.master?) && event.destroy
      return HESResponder(event)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

end