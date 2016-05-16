class GoMailer < ActionMailer::Base
  include AbstractController::Callbacks

  Domain = DomainConfig::DomainNames.first
  AppName = Constant::AppName
  FromAddress = "no-reply@#{Domain}"
  FormattedFromAddress = "#{AppName}<#{FromAddress}>"

  # see config/initializers/domain_config.rb
  default :from => FormattedFromAddress

  # see app/views/layouts/mailer.html.erb and app/views/layouts/mailer.text.erb
  layout 'mailer'

  helper :application

  def base_url(subdomain)
    return "https://#{subdomain}.#{GoMailer::Domain}"
  end

  def welcome_email(user)
    @user = user
    @promotion = user.promotion
    @base_url = self.base_url(user.promotion.subdomain)
    mail(:to => @user.email, :subject => "Welcome to #{Constant::AppName}!")
  end

  def contact_request_email(contact_request, subdomain)
    @contact_request = contact_request
    @promotion = Promotion.find_by_subdomain(subdomain) || Promotion.first
    @user = @promotion.users.first
    @base_url = self.base_url(@promotion.subdomain)
    mail(:to => contact_request['email'], :subject => "#{Constant::AppName}: Contact Request")
  end

  def invite_email(emails, user, message = nil)
    @user = user
    @promotion = @user.promotion
    @message = message
    @base_url = self.base_url(@promotion.subdomain)
    subject = "#{@user.profile.full_name} invited you to join #{Constant::AppName}"
    mail(:to => emails, :subject => subject, :from => fromHandler(@user))
  end
  
  def content_email(model, object, email, user, message = '')
    @model = model.constantize
    @object = object
    @user = user
    @promotion = @user.promotion
    @message = message
    @base_url = self.base_url(@promotion.subdomain)
    if @model.name == 'CustomContent'
      subject = "#{Constant::AppName} #{object['category'].titleize.singularize}: #{ActionView::Base.full_sanitizer.sanitize(HTMLEntities.new.decode(object['title_html'])).gsub(/[^a-z0-9\s]/i, '')}"
    else
      subject = "#{Constant::AppName} #{@model.name.titleize}: #{object['title'] || object['name'] || ''}"
    end
    mail(:to => email, :subject => subject, :from => fromHandler(@user)) do |format|
      format.text { render model.underscore.downcase }
      format.html { render model.underscore.downcase }
    end
  end

  def tip(tip, emails, user, message)
    @tip = tip
    @user = user
    @promotion = @user.promotion
    @message = message
    @base_url = self.base_url(@promotion.subdomain)
    mail(:to => emails, :subject => "#{Constant::AppName} Tip: #{tip.title}", :from => fromHandler(@user))
  end

  def recipe(recipe, emails, user, message)
    @recipe = recipe
    @user = user
    @promotion = @user.promotion
    @message = message
    @base_url = self.base_url(@promotion.subdomain)
    mail(:to => emails, :subject => "#{Constant::AppName} Recipe: #{recipe.title}", :from => fromHandler(@user))
  end

  def daily_email(day, promotion, to_name, to_email, base_url, user, custom_message = '')
    @tip = Tip.for_promotion(promotion).find_by_day(day)
    @recipe = Recipe.daily
    @promotion = promotion
    @user = user
    @base_url = self.base_url(@promotion.subdomain)
    @daily = true
    @custom_message = custom_message
    to = "#{to_name} <#{to_email}>"
    from = FormattedFromAddress
    reply_to = FromAddress
    sent_on = promotion.current_time
    headers 'return-path'=>FromAddress

    mail(:to => to, :subject => "#{@tip.email_subject}", :from => from, :reply_to => reply_to)
    
  end

  def reminder_email(reminder, promotion, to_name, to_email, base_url, user)
    @promotion = promotion
    @base_url = self.base_url(@promotion.subdomain)
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
    @promotion = @user.promotion
    @base_url = self.base_url(@promotion.subdomain)

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
    @promotion = @user.promotion
    @base_url = self.base_url(@promotion.subdomain)

    mail(:to => recipient, :subject => subject, :from => from, :reply_to => reply_to)
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
    @promotion = @from_user.promotion
    @base_url = self.base_url(@promotion.subdomain)
    mail(:to => to_user.email, :subject => subject, :from => fromHandler(@from_user))
  end

  def unregistered_team_invite_email(email, inviter, team, message = nil)
    @user = inviter
    @inviter = inviter
    @message = message
    @team = team
    @promotion = @inviter.promotion
    @base_url = self.base_url(@promotion.subdomain)
    mail(:to => email, :subject => "#{inviter.profile.full_name} invited you to join their team on #{Constant::AppName}", :from => fromHandler(@inviter))
  end

  def generic_email(emails, subject, message, from = nil, promotion = nil)
    @message = message
    # set the address first based on the from user
    # because we have to get some sort of user for the template and we don't want their email showing up...
    from_address = fromHandler(from)
    @user = from.nil? ? promotion.nil? ? Promotion.first.users.first : promotion.users.first : from
    @promotion = @user.promotion
    @base_url = self.base_url(@promotion.subdomain)
    if !emails.empty?
      mail(:to => emails, :subject => subject, :from => from_address)
    end
  end

  def one_time_email(emails, subject, message, from = nil, promotion = nil)
    @message = message
    # set the address first based on the from user
    # because we have to get some sort of user for the template and we don't want their email showing up...
    from_address = fromHandler(from)
    @user = from.nil? ? promotion.nil? ? Promotion.first.users.first : promotion.users.first : from
    @promotion = promotion
    @base_url = self.base_url(@promotion.subdomain)
    @no_preferences = true
    if !emails.empty?
      mail(:to => emails, :subject => subject, :from => from_address)
    end
  end

  def fromHandler(user = nil)
    return FormattedFromAddress if !user
    # todo: handle hiding emails based on promotion config and user preferences for future apps
    # KP doesn't care if they expose people's emails..
    return "#{user.profile.full_name} <no-reply@healthfortheholidays.com>"
  end

  def friend_invite_email(invitee, inviter)
    @invitee = invitee
    @user = invitee # NOTE: always need a @user for email templates
    @inviter = inviter
    @promotion = @inviter.promotion
    @base_url = self.base_url(@promotion.subdomain)
    mail(:to => @invitee.email, :subject => "#{Constant::AppName}: #{@inviter.profile.full_name} sent you a #{Friendship::Label} request", :from => fromHandler(@inviter))
  end

end
