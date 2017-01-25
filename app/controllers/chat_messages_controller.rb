class ChatMessagesController < ApplicationController
  authorize :index, :create, :show, :update, :hide_conversation, :user

  def index
    messages = []
    if params[:user_id]
      user_id = params[:user_id]
      messages = @current_user.messages.where("user_id = ? OR friend_id = ?", user_id, user_id)
    else

      # get recipient list with 1 or 2 of the latest messages
      messages_group = @current_user.messages.group(:friend_id, :user_id)
      messages_group.each do |mg|
        messages << mg
      end

      messages.sort_by{|m| m[:created_at]}
    end

    return HESResponder(messages)
  end

  def show
    message = ChatMessage.find(params[:id]) rescue nil
    if !message
      return HESResponder("Message", "NOT_FOUND")
    end
    return HESResponder(message)
  end

  def create
    @chat_message = @current_user.messages.build(params[:chat_message])
    if !@chat_message.valid?
      return HESResponder(@chat_message.errors.full_messages, "ERROR")
    end
    ChatMessage.transaction do
      @chat_message.save!
    end
    $redis.publish('newMessageCreated', @chat_message.to_json)
    return HESResponder(@chat_message)
  end

  def update
    message = ChatMessage.find(params[:id]) rescue nil
    if !message
      return HESResponder("Message", "NOT_FOUND")
    end
    if ![message.user.id, message.friend.id].include?(@current_user.id)
      return HESResponder("You can't view other users' messages.", "DENIED")
    end
    ChatMessage.transaction do
      message.update_attributes(params[:chat_message])
      if !message.valid?
        return HESResponder(message.errors.full_messages, "ERROR")
      end
    end
    return HESResponder(message)
  end

  def hide_conversation
    if params[:user_id]
      user_id = params[:user_id]
      messages = @current_user.messages.where("user_id = ? OR friend_id = ?", user_id, user_id)
      if messages.count == 0
        return HESResponder("Conversation does not exist", "ERROR")
      end
      messages.each do |m|
        if m.user_id == @current_user.id
          m.user_deleted = true
        elsif m.friend_id = @current_user.id
          m.friend_deleted = true
        end
        m.save
      end
    else
      return HESResponder("User ID Missing", "ERROR")
    end

    return HESResponder(messages)
  end

  def destroy
    return HESResponder("Can't delete.", "ERROR")
  end

end