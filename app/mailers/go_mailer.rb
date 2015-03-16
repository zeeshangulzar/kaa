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

  def friend_invite_email(invitee, inviter)
    @invitee = invitee
    @user = invitee # NOTE: always need a @user for email templates
    @inviter = inviter
    mail(:to => @invitee.email, :subject => "#{Constant::AppName}: #{@inviter.profile.full_name} sent you a #{Friendship::Label} request")
  end

  def chat_message_email(chat_message)
    @chat_message = chat_message
    @user = chat_message.friend
    mail(:to => @user.email, :subject => "#{Constant::AppName}: New message from #{@chat_message.user.profile.full_name}")
  end

  def challenge_received_email(challenge_sent, receiver)
    @challenge_sent = challenge_sent
    @user = receiver
    mail(:to => @user.email, :subject => "#{Constant::AppName}: New challenge from #{@challenge_sent.user.profile.full_name}")
  end

  def event_invite_email(event, user)
    @event = event
    @user = user
    mail(:to => @user.email, :subject => "#{@event.user.profile.full_name} invited you to #{@event.name}")
  end

  def content_email(model, object, emails, user, message)
    @model = model.constantize
    @object = object
    @user = user
    @promotion = @user.promotion
    @message = message
    subject = "#{Constant::AppName} #{@model.name.titleize}: #{object['title'] || object['name'] || ''}"


    mail(:to => emails, :subject => subject, :from => @user.email, :reply_to => @user.email) do |format|
      format.text { render model.underscore.downcase }
      format.html { render model.underscore.downcase }
    end
  end

  def tip(tip, emails, user, message)
    @tip = tip
    @user = user
    @promotion = @user.promotion
    @message = message
    mail(:to => emails, :subject => "#{Constant::AppName} Tip: #{tip.title}", :from => @user.email, :reply_to => @user.email)
  end

  def recipe(recipe, emails, user, message)
    @recipe = recipe
    @user = user
    @promotion = @user.promotion
    @message = message
    mail(:to => emails, :subject => "#{Constant::AppName} Recipe: #{recipe.title}", :from => @user.email, :reply_to => @user.email)
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

    
    mail(:to => to, :subject => "#{Constant::AppName}: #{@tip.email_subject}", :from => from, :reply_to => reply_to)

    #body :promotion => promotion, :organization => promotion.organization, :tip => tip, :recipe => rp, :base_url => base_url, :daily_email => true
    
  end



end
