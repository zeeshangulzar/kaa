class FriendshipsController < ApplicationController
  authorize :all, :user

  def index
    if @target_user.id != @current_user.id && !@current_user.master?
      return HESResponder("You can't see this user's friendships.", "DENIED")
    end
    if params[:status]
      case params[:status]
        when 'all'
          f = @target_user.friendships.includes(:friendee => :profile)
        when 'sent_requests'
          f = @target_user.friendships.pending.where("sender_id = #{@target_user.id}").includes(:friendee => :profile)
        when 'received_requests'
          f = @target_user.friendships.pending.where("sender_id <> #{@target_user.id}").includes(:friendee => :profile)
        else
          if Friendship::STATUS.stringify_keys.keys.include?(params[:status])
            # ?status=[pending, accepted, etc.]
            f = @target_user.friendships.send(params[:status]).includes(:friendee => :profile)
          elsif Friendship::STATUS.values.include?(params[:status])
            # ?status=[P, R, A, D]
            f = @target_user.friendships.send(Friendship::STATUS.index(params[:status]).to_s).includes(:friendee => :profile)
          else
            return HESResponder("No such status.", "ERROR")
          end
      end
    else
      f = @target_user.friendships.includes(:friendee => :profile)
    end
    f.sort!{|a,b|a.friendee.profile.last_name.downcase <=> b.friendee.profile.last_name.downcase}

    f.sort!{ |a,b| 
      result = false
      if a.friendee.nil? && b.friendee.nil?
        result = (a.friend_email.to_s.downcase <=> b.friend_email.to_s.downcase)
      elsif a.friendee.nil?
        result = (a.friend_email.to_s.downcase <=> b.friendee.profile.last_name.downcase)
      elsif b.friendee.nil?
        result = (a.friendee.profile.last_name.downcase <=> b.friend_email.to_s.downcase)
      else
        result = (a.friendee.profile.last_name.downcase <=> b.friendee.profile.last_name.downcase)
      end
      result
    }

    # find all accepted friendships, get all their stats in 1 query, apply those stats to the friender and/or friendee of the friendship 
    accepted = f.select{|friendship|friendship.accepted?}
    stats_ids = accepted.collect{|friendship|[friendship.friendee_id,friendship.friender_id]}.flatten.uniq
    stats = User.stats(stats_ids) unless stats_ids.empty?
    accepted.each do |accepted|
      # check loaded? to ensure it doesn't unnecessarily load friender or friendee
      accepted.friendee.attach('total_points', stats[accepted.friendee_id]['total_points']) if accepted.association(:friendee).loaded?
    end

    return HESResponder(f)
  end

  def show
    friendship = Friendship.find(params[:id]) rescue nil
    if !friendship
      return HESResponder("Friendship", "NOT_FOUND")
    else
      if [friendship.friender_id, friendship.friendee_id].include?(@current_user.id) || @current_user.master?
        return HESResponder(friendship)
      else
        return HESResponder("You may not view this friendship.", "DENIED")
      end
    end
  end

  def create
    friendship = nil;
    if @target_user.id != @current_user.id && !@current_user.master?
      return HESResponder("You can't alter other users' friendships.", "DENIED")
    end
    declined = @target_user.friendships.where("(friendee_id = ? AND friender_id = ?) AND status = ?", params[:friendee_id], @current_user.id, Friendship::STATUS[:declined])
    Friendship.transaction do
      if !declined.empty?
        friendship = declined.first
        attrs = params[:friendship].merge({:status => Friendship::STATUS[:pending]})
        friendship.update_attributes(attrs)
      else
        if params[:friendship][:id] && params[:resend]
          f = @target_user.friendships.find(params[:friendship][:id]) rescue nil
          return HESResponder("Friendship", "NOT_FOUND") if f.nil?
          f.send_requested_notification
        else
          friendship = @target_user ? @target_user.friendships.create(params[:friendship]) : Friendship.create(params[:friendship])
        end
      end
    end 
    return HESResponder(friendship.errors.full_messages, "ERROR") if !friendship.valid?
    return HESResponder(friendship)
  end

  def update
    friendship = Friendship.find(params[:id]) rescue nil
    return HESResponder("Friendship", "NOT_FOUND") if friendship.nil?

    # don't want them changing the user ids..
    [:friender_id, :friendee_id].each { |k| params[:friendship].delete(k) rescue nil }

    if [friendship.friender.id, friendship.friendee.id].include?(@current_user.id) || @current_user.master?
      if !params[:friendship].nil? && !params[:friendship][:status].nil? && params[:friendship][:status] == Friendship::STATUS[:accepted] && !@current_user.master? && @current_user.id == friendship.sender.id
        return HESResponder("Can't accept your own invite.", "ERROR")
      end
      Friendship.transaction do
        friendship.update_attributes(params[:friendship])
      end
      return HESResponder(friendship.errors.full_messages, "ERROR") if !friendship.valid?
      if friendship.accepted?
        stats = User.stats(friendship.friendee_id)
        friendship.friendee.stats = stats[friendship.friendee_id]
      end
      return HESResponder(friendship)
    end
  end

  def destroy
    friendship = Friendship.find(params[:id]) rescue nil
    return HESResponder("Friendship", "NOT_FOUND") if friendship.nil?

    if friendship.friender.id == @current_user.id || @current_user.master? || (friendship.friendee && friendship.friendee.id == @current_user.id)
      Friendship.transaction do
        friendship.destroy
      end
      return HESResponder(friendship)
    else
      return HESREsponder("You are not allowed to delete this friendship.", "DENIED")
    end
  end
end
