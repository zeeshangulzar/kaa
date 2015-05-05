class EmailsController < ApplicationController
  respond_to :json
  authorize :unsubscribe, :public
  authorize :all, :user

  # Sends content, like tips, articles and recipes, in an email to someone inside or outside the promotion
  #
  # @url [POST] /emails/content
  # @authorize User
  # @param [String] model The name of the model being sent in an email. For example, "Recipe" or "Tip".
  # @param [Integer] id The id of the instance of the model being sent in an email.
  # @param [String] emails An array of emails that are receiving the content email
  # @param [String] message The message sent along with the content to the recipient
  # @return [Hash] Message the email was sent successfully
  #
  # [URL] /emails/content [POST]
  #  [200 OK] Successfully sent email
  #   # Example response
  #   {
  #     "success": true
  #   }
  def content
    object = params[:model].constantize.find(params[:id]) rescue nil
    return HESResponder("Object", "NOT_FOUND") if !object
    return HESResponder("Must include at least 1 email address.", "ERROR") if params[:emails].nil?
    Resque.enqueue(ContentEmail, params[:model], object, params[:emails], @current_user.id, params[:message])
    return HESResponder()
  end

  def invite
    return HESResponder("Must include at least 1 email address.", "ERROR") if params[:emails].nil?
    message = params[:message] rescue nil
    Resque.enqueue(InviteEmail, params[:emails], @current_user.id, message)
    return HESResponder()
  end

  def unsubscribe
    return HESResponder("Must provide email.", "ERROR") if params[:email].nil?
    user = @promotion.users.where(:email => params[:email]).first rescue nil
    if !user
      unsubscribe = @promotion.unsubscribe_list.build(:email => params[:email])
    elsif user && !@current_user || @current_user.id != user.id
      return HESResponder("Please login to unsubscribe.", "DENIED")
    elsif user && @current_user && @current_user.id == user.id
      unsubscribe = @promotion.unsubscribe_list.build(:email => params[:email], :user_id => @current_user.id)
    else
      return HESResponder("General failure.", "ERROR")
    end
    return HESResponder(unsubscribe.errors.full_messages, "ERROR") if !unsubscribe.valid?
    UnsubscribeList.transaction do
      unsubscribe.save!
    end
    return HESResponder(unsubscribe)
  end
end