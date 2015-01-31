# Controller for handling all friendship requests
class FriendshipsController < ApplicationController
  respond_to :json

  # Get the user before each request
  # before_filter :get_user_with_friends

  # Get the friendable_id before these requests
  before_filter :get_friendable, :only => [:index, :show, :create, :update]

  authorize :all, :user

  # Get the friendable instance or render an error
  # @param [Integer] friendable id of the instance with the friendships
  # @param [String] friendable type of the instance with the friendships
  def get_friendable
    if !params[:friendable_id].nil? && !params[:friendable_type].nil?
      @friendable = params[:friendable_type].singularize.camelcase.constantize.find(params[:friendable_id])
    elsif params[:id]
      @friendable = Friendship.find(params[:id]) rescue nil
      return HESResponder("Friendship", "NOT_FOUND") if !@friendable
    else
      @friendable = @current_user
    end
  end


  # Gets the list of friendships for a user instance
  #
  # @return [Array] of all friendships
  #
  # [URL] /users/1/friendships [GET]
  #  [200 OK] Successfully retrieved Friendships Array object
  #   # Example response
  #   [
  #    {
  #     "status": "A",
  #     "friender_id": 1,
  #     "friender_type": "User",
  #     "friendee_id": "2",
  #     "friendee_type": "User",
  #     "friendee": {
  #       name: "Ryan",
  #       email: "ryann@hesonline.com"
  #     },
  #     "friender": {
  #       name: "John",
  #       email: "johns@hesnoline.com"
  #     }
  #    }
  #   ]
  def index
    if @friendable.id != @current_user.id && !@current_user.master?
      return HESResponder("You can't see this user's friendships.", "DENIED")
    end
    if params[:status]
      case params[:status]
        when 'all'
          f = @friendable.friendships.includes(:friendee => :profile)
        when 'sent_requests'
          f = @friendable.friendships.pending.where("sender_id = #{@friendable.id}").includes(:friendee => :profile)
        when 'received_requests'
          f = @friendable.friendships.pending.where("sender_id <> #{@friendable.id}").includes(:friendee => :profile)
        else
          if Friendship::STATUS.stringify_keys.keys.include?(params[:status])
            # ?status=[pending, accepted, etc.]
            f = @friendable.friendships.send(params[:status]).includes(:friendee => :profile)
          elsif Friendship::STATUS.values.include?(params[:status])
            # ?status=[P, R, A, D]
            f = @friendable.friendships.send(Friendship::STATUS.index(params[:status]).to_s).includes(:friendee => :profile)
          else
            return HESResponder("No such status.", "ERROR")
          end
      end
    else
      f = @friendable.friendships.includes(:friendee => :profile)
    end
    f.sort!{|a,b|a.friendee.profile.last_name.downcase <=> b.friendee.profile.last_name.downcase}
    return HESResponder(f)
  end

  # Gets a single friendship for a user
  #
  # @example
  #  #GET /users/1/friendships/2
  #
  # @param [String] friendable type
  # @param [Integer] friendable id
  # @param [Integer] id of the friendship
  # @return [Friendship] that matches the id
  #
  # [URL] /users/1/friendships/2 [GET]
  #  [200 OK] Successfully retrieved Friendship object
  #   # Example response
  #   {
  #    "status": "A",
  #    "friender_id": 1,
  #    "friender_type": "User",
  #    "friendee_id": "2",
  #    "friendee_type": "User",
  #    "friendee": {
  #     name: "Ryan",
  #     email: "ryann@hesonline.com"
  #    },
  #    "friender": {
  #     name: "John",
  #     email: "johns@hesnoline.com"
  #    }
  #   }
  def show
    @friendship = Friendship.find(params[:id]) rescue nil
    if !@friendship
      return HESResponder("Friendship", "NOT_FOUND")
    else
      if [@friendship.friender_id, @friendship.friendee_id].include?(@current_user.id) || @current_user.master?
        return HESResponder(@friendship)
      else
        return HESResponder("You may not view this friendship.", "DENIED")
      end
    end
  end

  # Creates a single friendship for a user
  #
  # @example
  #  #POST /friendships
  #  {
  #    friender_id: 1,
  #    friender_type: 'User',
  #    friendee_id: 2,
  #    friendee_type: 'User',
  #    status: 'P',
  #    friend_email: 'ryann@hesonline.com'
  #  }
  # @return [Friendship] that was just created
  #
  # [URL] /friendships [POST]
  #  [201 CREATED] Successfully created Friendship object
  #   # Example response
  #   {
  #    "status": "P",
  #    "friendee": {
  #     name: "Ryan",
  #     email: "ryann@hesonline.com"
  #    },
  #    "friender": {
  #     name: "John",
  #     email: "johns@hesnoline.com"
  #    }
  #   }
  def create
    if @friendable.id != @current_user.id && !@current_user.master?
      return HESResponder("You can't alter other users' friendships.", "DENIED")
    end
    Friendship.transaction do
      @friendship = @friendable ? @friendable.friendships.create(params[:friendship]) : Friendship.create(params[:friendship])
    end
    if !@friendship.valid?
      return HESResponder(@friendship.errors.full_messages, "ERROR")
    end
    return HESResponder(@friendship)
  end

  # Updates a single friendship for a user
  #
  # @example
  #  #PUT /friendships/2
  #  {
  #    status: 'A'
  #  }
  #
  # @param [Integer] id of the friendship
  # @return [Friendship] that was just updated
  #
  # [URL] /friendships/2 [PUT]
  #  [202 ACCEPTED] Successfully updated Friendship object
  #   # Example response
  #   {
  #    "status": "A",
  #    "friender_id": 1,
  #    "friender_type": "User",
  #    "friendee_id": "2",
  #    "friendee_type": "User",
  #    "friendee": {
  #     name: "Ryan",
  #     email: "ryann@hesonline.com"
  #    },
  #    "friender": {
  #     name: "John",
  #     email: "johns@hesnoline.com"
  #    }
  #   }
  def update
    @friendship = Friendship.find(params[:id]) rescue nil
    if !@friendship
      return HESResponder("Friendship", "NOT_FOUND")
    end
    # don't want them changing the user ids..
    [:friender_id, :friendee_id].each { |k| params[:friendship].delete(k) rescue nil }

    if [@friendship.friender.id, @friendship.friendee.id].include?(@current_user.id) || @current_user.master?
      if !params[:friendship].nil? && !params[:friendship][:status].nil? && params[:friendship][:status] == Friendship::STATUS[:accepted] && !@current_user.master? && @current_user.id == @friendship.sender.id
        return HESResponder("Can't accept your own invite.", "ERROR")
      end
      Friendship.transaction do
        @friendship.update_attributes(params[:friendship])
      end
      if !@friendship.valid?
        return HESResponder(@friendship.errors.full_messages, "ERROR")
      end
      return HESResponder(@friendship)
    end
  end

  # Deletes a single friendship from a user
  #
  # @example
  #  #DELETE /friendships/2
  #
  # @param [Integer] id of the friendship
  # @return [friendship] that was just deleted
  #
  # [URL] /friendships/2 [DELETE]
  #  [200 OK] Successfully destroyed Friendship object
  #   # Example response
  #   {
  #    "status": "A",
  #    "friender_id": 1,
  #    "friender_type": "User",
  #    "friendee_id": "2",
  #    "friendee_type": "User",
  #    "friendee": {
  #     name: "Ryan",
  #     email: "ryann@hesonline.com"
  #    },
  #    "friender": {
  #     name: "John",
  #     email: "johns@hesnoline.com"
  #    }
  #   }
  def destroy
    @friendship = Friendship.find(params[:id]) rescue nil
    if !@friendship
      return HESResponder("Friendship", "NOT_FOUND")
    end
    if @friendship.friender.id == @current_user.id || @current_user.master? || (@friendship.friendee && @friendship.friendee.id == @current_user.id)
      Friendship.transaction do
        @friendship.destroy
      end
      return HESResponder(@friendship)
    else
      return HESREsponder("You are not allowed to delete this friendship.", "DENIED")
    end
  end
end
