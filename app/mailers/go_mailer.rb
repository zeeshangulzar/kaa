class GoMailer < ActionMailer::Base
  # see config/initializers/domain_config.rb
  default :from=>"#{Constant::AppName}<no-reply@#{DomainConfig::DomainNames.first}>"

  # see app/views/layouts/mailer.html.erb and app/views/layouts/mailer.text.erb
  layout 'mailer'

  def welcome_email(user)
    @user = user
    mail(:to => @user.email, :subject => "Welcome to #{Constant::AppName}!")
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

end
