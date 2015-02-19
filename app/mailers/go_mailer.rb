class GoMailer < ActionMailer::Base
  # see config/initializers/domain_config.rb
  default :from=>"#{Constant::AppName}<no-reply@#{DomainConfig::DomainNames.first}>"

  # see app/views/layouts/mailer.html.erb and app/views/layouts/mailer.text.erb
  layout 'mailer'

  def dummy_email(entry)
    # see app/views/go_mailer/dummy_email.html.erb and app/views/go_mailer/dummy_email.text.erb
    @entry = entry
    @user = entry.user
    mail(:to => entry.user.email, :subject => 'You logged something!')
  end

  def welcome_email(user)
    @user = user
    mail(:to => @user.email, :subject => "Welcome to #{Constant::AppName}!")
  end

  def event_invite_email(event, user)
    @event = event
    @user = user
    mail(:to => @user.email, :subject => "#{@event.user.profile.full_name} invited you to #{@event.name}")
  end
end
