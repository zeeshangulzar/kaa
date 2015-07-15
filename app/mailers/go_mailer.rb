class GoMailer < ActionMailer::Base

  Domain = DomainConfig::DomainNames.first
  AppName = Constant::AppName
  FromAddress = "no-reply@#{Domain}"
  FormattedFromAddress = "#{AppName}<#{FromAddress}>"

  # see config/initializers/domain_config.rb
  default :from => FormattedFromAddress

  # see app/views/layouts/mailer.html.erb and app/views/layouts/mailer.text.erb
  layout 'mailer'

  helper :application

  def welcome_email(user)
    @user = user
    mail(:to => @user.email, :subject => "Welcome to #{Constant::AppName}!")
  end

  def contact_request_email(contact_request, subdomain)
    @contact_request = contact_request
    @promotion = Promotion.find_by_subdomain(subdomain) || Promotion.first
    @user = @promotion.users.first
    mail(:to => contact_request['email'], :subject => "#{Constant::AppName}: Contact Request")
  end

  def friend_invite_email(invitee, inviter)
    @invitee = invitee
    @user = invitee # NOTE: always need a @user for email templates
    @inviter = inviter
    @promotion = @invitee.promotion
    mail(:to => @invitee.email, :subject => "#{Constant::AppName}: #{@inviter.profile.full_name} sent you a #{Friendship::Label} request", :from => fromHandler(@inviter))
  end

  def chat_message_email(chat_message)
    @chat_message = chat_message
    @user = chat_message.friend
    mail(:to => @user.email, :subject => "#{Constant::AppName}: New message from #{@chat_message.user.profile.full_name}", :from => fromHandler(@chat_message.user))
  end

  def invite_email(emails, user, message = nil)
    @user = user
    @promotion = @user.promotion
    @message = message
    subject = "#{@user.profile.full_name} invited you to join #{Constant::AppName}"
    mail(:to => emails, :subject => subject, :from => fromHandler(@user))
  end
  
  def content_email(model, object, emails, user, message)
    @model = model.constantize
    @object = object
    @user = user
    @promotion = @user.promotion
    @message = message
    subject = "#{Constant::AppName} #{@model.name.titleize}: #{object['title'] || object['name'] || ''}"

    mail(:to => emails, :subject => subject, :from => fromHandler(@user)) do |format|
      format.text { render model.underscore.downcase }
      format.html { render model.underscore.downcase }
    end
  end

  def tip(tip, emails, user, message)
    @tip = tip
    @user = user
    @promotion = @user.promotion
    @message = message
    mail(:to => emails, :subject => "#{Constant::AppName} Tip: #{tip.title}", :from => fromHandler(@user))
  end

  def recipe(recipe, emails, user, message)
    @recipe = recipe
    @user = user
    @promotion = @user.promotion
    @message = message
    mail(:to => emails, :subject => "#{Constant::AppName} Recipe: #{recipe.title}", :from => fromHandler(@user))
  end

  def daily_email(day, promotion, to_name, to_email, base_url, user)
    @tip = Tip.for_promotion(promotion).find_by_day(day)
    @recipe = Recipe.daily
    @promotion = promotion
    @user = user

    to = "#{to_name} <#{to_email}>"
    from = FormattedFromAddress
    reply_to = FromAddress
    sent_on = promotion.current_time
    headers 'return-path'=>FromAddress

    mail(:to => to, :subject => "#{@tip.title}", :from => from, :reply_to => reply_to)
    
  end

  def reminder_email(reminder, promotion, to_name, to_email, base_url, user)
    @promotion = promotion
    @user = user
    @reminder = reminder
    to = "#{to_name} <#{to_email}>"
    from = FormattedFromAddress
    reply_to = FromAddress
    sent_on = promotion.current_time
    headers 'return-path'=>FromAddress

    mail(:to => to, :subject => "#{Constant::AppName}: #{@reminder.subject}", :from => from, :reply_to => reply_to)
    
  end


  def daily_tasks(b)
    mail(:from => FormattedFromAddress, :to => "developer@hesonline.com", :subject => "Daily Tasks for #{Date.today}", :body => b)
  end

  def password_reset(user, base_url)
    subject = "#{AppName}: Password Reset"
    recipient = "#{user.email}"
    from = FormattedFromAddress
    reply_to = FromAddress

    @link = "http#{'s' unless Rails.env.to_s=='development'}://#{base_url}/#/contact"
    @user = user
    @host = "#{base_url}"

    mail(:to => recipient, :subject => subject, :from => from, :reply_to => reply_to)
  end

  def forgot_password(user, base_url)
    subject = "#{AppName}: Forgot Password"
    recipient = "#{user.email}"
    from = FormattedFromAddress
    reply_to = FromAddress

    user.initialize_aes_iv_and_key_if_blank!
    key="#{SecureRandom.hex(4)}~#{user.id}~#{Time.now.utc.to_f}~#{user.updated_at.to_f}"
    encrypted_key = user.aes_encrypt(key)
    encoded_encrypted_key = PerModelEncryption.url_base64_encode(encrypted_key).chomp
    encrypted_id_link = Encryption.encrypt("#{user.id}~#{encoded_encrypted_key}")
    encoded_encrypted_id_link = PerModelEncryption.url_base64_encode(encrypted_id_link).chomp

    @link = "http#{'s' unless Rails.env.to_s=='development'}://#{base_url}/#/password_reset/#{CGI.escape(encoded_encrypted_id_link)}"
    @user = user
    @host = "#{base_url}"

    mail(:to => recipient, :subject => subject, :from => from, :reply_to => reply_to)
  end

  def kp_verification(promotion, base_url, file_names, email_recipients, email_subject)
    p = promotion
    @user = p.users.first
    subject = "#{'Empty ' if file_names.empty?}#{email_subject}"
    recipient = email_recipients 
    from = FormattedFromAddress
    reply_to = "#{AppName}<kpfulfillment@hesonline.com>"
    sent_on = p.current_time
    headers 'return-path'=>FromAddress

    file_names.each do |fn|
      attachments["#{File.basename(fn)}"] = File.read(fn)
    end

    @message = file_names.empty? ? "There are no verification files today." : "The verification files are attached.  Please only fill in the columns labeled 'Eligible?' and 'Comments'. Please send the completed files to kpfulfillment@hesonline.com"

    mail(:to => recipient, :subject => subject, :from => from, :subject => subject, :reply_to => reply_to, :body => subject)
  end
  
  def team_invite_email(invite_type, to_user, from_user, team, message = nil)
    if invite_type == 'requested'
      subject = "#{from_user.profile.full_name} has requested to join your team on #{Constant::AppName}"
    else
      subject = "#{from_user.profile.full_name} invited you to join their team on #{Constant::AppName}"
    end
    @user = from_user
    @from_user = from_user
    @to_user = to_user
    @invite_type = invite_type
    @message = message
    @team = team
    mail(:to => to_user.email, :subject => subject, :from => fromHandler(@from_user))
  end

  def unregistered_team_invite_email(email, inviter, team, message = nil)
    @user = inviter
    @inviter = inviter
    @message = message
    @team = team
    mail(:to => email, :subject => "#{inviter.profile.full_name} invited you to join their team on #{Constant::AppName}", :from => fromHandler(@inviter))
  end

  def generic_email(emails, subject, message, from = nil, promotion = nil)
    @message = message
    # set the address first based on the from user
    # because we have to get some sort of user for the template and we don't want their email showing up...
    from_address = fromHandler(from)
    @user = from.nil? ? promotion.nil? ? Promotion.first.users.first : promotion.users.first : from
    if !emails.empty?
      mail(:to => emails, :subject => subject, :from => from_address)
    end
  end

  def fromHandler(user = nil)
    return FormattedFromAddress if !user
    # todo: handle hiding emails based on promotion config and user preferences for future apps
    # KP doesn't care if they expose people's emails..
    return "#{user.profile.full_name} <#{user.email}>"
  end

end
