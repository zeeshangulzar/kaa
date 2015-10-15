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
    emails = params[:emails].is_a?(Array) ? params[:emails] : [params[:emails]]
    emails.each_with_index{|email,index|
      emails[index] = email.strip.gsub(/\A"|"\Z/, '').strip
    }
    Resque.enqueue(ContentEmail, params[:model], object, emails, @current_user.id, params[:message])
    return HESResponder()
  end

  def invite
    return HESResponder("Must include at least 1 email address.", "ERROR") if params[:emails].nil?
    message = params[:message] rescue nil
    Resque.enqueue(InviteEmail, params[:emails], @current_user.id, message)
    return HESResponder()
  end

  def unsubscribe
    return HESResponder("Must provide email.", "ERROR") if params[:promotion_id].nil? || params[:email].nil?
    email = Encryption::decrypt(Base64.decode64(CGI.unescape("#{params[:email]}")))
    user = @promotion.users.where(:email => email).first rescue nil
    if user
      if user.allows_email
        User.transaction do
          user.update_attributes(:allows_email => false)
        end
      end
    else
      return HESResponder("General failure.", "ERROR")
    end
    return HESResponder()
  end

  def send_mail
    return HESResponder("Message, recipient and type required.", "ERROR") if params[:message].nil? || params[:recipient_id].nil? || params[:email_type].nil?
    message = params[:message]
    emails = []
    if params[:email_type] == 'team'
      team = Team.find(params[:recipient_id]) rescue nil
      return HESResponder("Team", "NOT_FOUND") if !team
      emails = team.members.collect{|member|member.email}
      subject = "#{@current_user.profile.full_name} sent your team a message via #{Constant::AppName}"
    elsif params[:email_type] == 'individual'
      user = User.find(params[:recipient_id]) rescue nil
      return HESResponder("User", "NOT_FOUND") if !user
      emails = [user.email]
      subject = "#{@current_user.profile.full_name} sent you a message via #{Constant::AppName}"
    end
    Resque.enqueue(GenericEmail, emails, subject, message, @current_user.id) unless emails.empty?
    return HESResponder()
  end

end
