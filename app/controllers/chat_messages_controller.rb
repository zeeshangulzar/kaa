class ChatMessagesController < ApplicationController
  authorize :index, :create, :show, :update, :user

  def index
    return HESResponder(@current_user.messages)
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
      if !message.vaild?
        return HESResponder(message.errors.full_messages, "ERROR")
      end
    end
    return HESResponder(message)
  end

  def destroy
    return HESResponder("Can't delete.", "ERROR")
  end

end