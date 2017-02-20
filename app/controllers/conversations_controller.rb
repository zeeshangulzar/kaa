class ConversationsController < ApplicationController

  before_filter :validate_creator, only: [:create]
  before_filter :validate_conversation_type, only: [:create]

  def create
    conversation = Conversation.create_conversation(params)
    return HESResponder("Conversation Created") if conversation.present?
    return HESResponder("Conversation not created successfully")
  end

  private

    def validate_creator
      return HESResponder("creator_id not found", "ERROR") if params[:creator_id].blank?
      return HESResponder("Invalid creator id", "ERROR")   if User.find_by_id(params[:creator_id]).blank?
    end

    def validate_conversation_type
      return HESResponder("conversation_type not found", "ERROR") if params[:conversation_type].blank?
      return HESResponder("Invalid conversation_type", "ERROR")   unless params[:conversation_type].in?(Conversation::CONVERSATION_TYPES)
    end

end
