class Task

  def self.execute_daily_tasks(send_emails=false)
    body = ""
    Promotion.find(:all, :conditions => "subdomain = 'www'").each do |p|
      begin
        body<<"===================================================================================================\n"
        send_daily_emails(p) if send_emails && ![0,6].include?(Date.today.wday) # Use the && condition if you want skip sending emails for certain days. See SkipDays in tip.rb.
      rescue Exception => ex
        body<<"ERROR processing promotion #{p.subdomain} #{ex.to_s}\n#{ex.backtrace.join("\n")}"
      end
    body<<"===================================================================================================\n\n\n\n"
    end
    GoMailer.daily_tasks(body).deliver!
  end
  
  def self.send_daily_emails(p)
      if ![0,6].include?(p.current_date.wday)
        queue = true#true unless IS_STAGING #|| RAILS_ENV=='development'

        users = p.users.includes(:profile).where("profiles.started_on <= '#{p.current_date}'")

        day = Tip.get_day_number_from_date(p.current_date)

        mails=[]

        users.each{ |u|

          what_to_send = 'daily_email'

          p.email_reminders.desc.each{|reminder|
            if ( u.last_login < (p.current_time - (reminder.days).days) ) && !u.email_reminders.include?(reminder)
              what_to_send = 'reminder'
              email_reminder = reminder
              break
            end
          }

          if !u.flags[:allow_daily_emails_all_week]
            what_to_send = 'nothing'
          elsif p.current_date.wday != 1 && u.flags[:allow_daily_emails_monday]
            what_to_send = 'nothing'
          end

          begin
            if queue
              case what_to_send
                when 'daily_email'
                    mails << GoMailer.daily_email(day, p, GoMailer::AppName,"admin@#{DomainConfig::DomainNames.first}", "#{p.subdomain}.#{DomainConfig::DomainNames.first}", u)
                    mails.last.bcc='' # not sure why TMail doesn't just make this an empty array to begin with...
                when 'reminder'
                    d=which.to_s.split('reminder_').last.to_i
                    mails << GoMailer.create_no_activity_reminder_email(d,p,Mailer::AppName,"admin@#{DomainConfig::DomainNames.first}","#{p.subdomain}.#{DomainConfig::DomainNames.first}")
                    mails.last.bcc='' # not sure why TMail doesn't just make this an empty array to begin with...
              else
              end
              mails.last.bcc = u.email_with_name
              to = mails.last.bcc
            end
            puts "#{queue ? 'Queue' : 'Deliver'} #{what_to_send} to #{to}"
          rescue Exception => ex
            puts "ERROR processing user #{u.id} #{ex.to_s}\n#{ex.backtrace.join("\n")}"
          end
        } # end each user

        if queue
          # make the XML file for this promotion
          tag = "gokp-#{Date.today.strftime('%Y%m%d')}-daily-email-#{p.id}-#{p.subdomain}"
          XmlEmailDelivery.deliver_many(mails,tag) unless mails.empty?
        end

      end # end wday not 0,6


  end

end



