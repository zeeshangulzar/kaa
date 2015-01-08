class ChatMessagesController < ApplicationController
  authorize :index, :create, :show, :update, :user

  def index
    return HESResponder2(@current_user.messages)
  end

  def show
    message = ChatMessage.find(params[:id]) rescue nil
    if !message
      return HESResponder2("Message", "NOT_FOUND")
    end
    return HESResponder2(message)
  end

  def create
    @chat_message = @current_user.messages.create(params[:chat_message])
    return HESResponder2(@chat_message)
  end

  def update
    message = ChatMessage.find(params[:id]) rescue nil
    if !message
      return HESResponder2("Message", "NOT_FOUND")
    end
    if ![message.user.id, message.friend.id].include?(@current_user.id)
      return HESResponder2("You can't view other users' messages.", "DENIED")
    end
    ChatMessage.transaction do
      message.update_attributes(params[:chat_message])
      if !message.vaild?
        return HESResponder2(message.errors.full_messages, "ERROR")
      end
    end
    return HESResponder2(message)
  end

  def destroy
    return HESResponder2("Can't delete.", "ERROR")
  end

end