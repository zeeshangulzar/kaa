class ConversationsController < ApplicationController

  before_filter :validate_creator, only: [:create]
  before_filter :validate_conversation_type, only: [:create]
  before_filter :validate_conversation, only: [:messages]
  before_filter :validate_conversation_user, only: [:messages]
  before_filter :validate_get_request, only: [:messages]
  before_filter :validate_message_content, only: [:messages]

  def create
    conversation = Conversation.create_conversation(params)
    return HESResponder("Conversation Created") if conversation.present?
    return HESResponder("Conversation not created successfully")
  end

  def messages
    message = Message.save_message(@target_user.id, params[:content])
    return HESResponder("Message Created")
  end

  private

    def validate_creator
      return HESResponder("creator_id not found", "ERROR") if params[:creator_id].blank?
      return HESResponder("Invalid creator_id", "ERROR")   if User.find_by_id(params[:creator_id]).blank?
    end

    def validate_conversation_type
      return HESResponder("conversation_type not found", "ERROR") if params[:conversation_type].blank?
      return HESResponder("Invalid conversation_type", "ERROR")   unless params[:conversation_type].in?(Conversation::CONVERSATION_TYPES)
    end

    def validate_conversation
      return HESResponder("conversation_id not found", "ERROR") if params[:conversation_id].blank?
      @conversation = Conversation.find_by_id(params[:conversation_id])
      return HESResponder("Invalid conversation_id", "ERROR")   if @conversation.blank?
    end

    def validate_conversation_user
      @user = ConversationUser.where(user_id: @target_user.id, conversation_id: @conversation.id).last
      return HESResponder("invalid conversation_user", "ERROR") if @user.blank?
    end

    def validate_get_request
      return if request.post?
      @user.last_read_at = Time.now
      flag = @user.save
      return HESResponder("last_read_at not updated successfully", "ERROR") if flag.blank?
      return HESResponder("last_read_at updated successfully")
    end

    def validate_message_content
      return HESResponder("message content not found", "ERROR") if params[:content].blank?
    end

end
