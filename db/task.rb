class Task

  def self.execute_daily_tasks(send_emails=false)
    body = ""
    Promotion.find(:all, :conditions => "subdomain = 'www'").each do |p|
      begin
        body<<"===================================================================================================\n"
        send_daily_emails(p) if send_emails && ![0,6].include?(Date.today.wday) # Use the && condition if you want skip sending emails for certain days. See SkipDays in tip.rb.
        team_notifications(p) unless p.current_competition.nil?
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
        addresses=[]

        daily_email = false

        users.each{ |u|
          what_to_send = 'daily_email'
          email_reminder = false

          if !u.flags[:allow_daily_emails_all_week]
            what_to_send = 'nothing'
          elsif p.current_date.wday != 1 && u.flags[:allow_daily_emails_monday]
            what_to_send = 'nothing'
          end

          unless u.requests.count < 1
            p.email_reminders.desc.each{ |reminder|
              if ( u.requests.first.created_at < (p.current_time - (reminder.days).days) ) && !u.email_reminders.include?(reminder)
                what_to_send = 'reminder'
                email_reminder = reminder
                u.email_reminders_sent.create(:email_reminder_id => reminder.id)
                break
              end
            }
          end

          skip = false

          begin
            case what_to_send
              when 'daily_email'
                # cache rendered daily email..
                if !daily_email
                  daily_email = GoMailer.daily_email(day, p, GoMailer::AppName,"admin@#{DomainConfig::DomainNames.first}", "#{p.subdomain}.#{DomainConfig::DomainNames.first}", u)
                end
                mails << daily_email
              when 'reminder'
                reminder_email = GoMailer.reminder_email(email_reminder, p, GoMailer::AppName,"admin@#{DomainConfig::DomainNames.first}", "#{p.subdomain}.#{DomainConfig::DomainNames.first}", u)
                mails << reminder_email
            else
              skip = true
            end
            to = u.email_with_name
            addresses << CGI.unescapeHTML(to) unless skip
            puts "#{queue ? 'Queue' : 'Deliver'} #{what_to_send} to #{to}"
          rescue Exception => ex
            puts "ERROR processing user #{u.id} #{ex.to_s}\n#{ex.backtrace.join("\n")}"
          end
        } # end each user
        if queue
          # make the XML file for this promotion
          tag = "gokp-#{Date.today.strftime('%Y%m%d')}-daily-email-#{p.id}-#{p.subdomain}"
          XmlEmailDelivery.deliver_many(mails,tag,addresses) unless mails.empty?
        else
          mails.each_with_index{ |mail, idx|
            mail.bcc = addresses[idx]
            mail.deliver
          }
        end

      end # end wday not 0,6
  end

  def self.team_notifications(p)
    c = p.current_competition
    return unless c
    if (c.enrollment_ends_on - p.current_date < 8)
      c.teams.pending.each{ |team|
        needed = c.team_size_min - team.members.count
        unless team.leader.notifications.find(:first, :conditions => [:key => "enrollment_ends_#{c.id}"]) || needed < 1
          notify(team.leader, "Enrollment Ends Soon", "Team enrollment ends on #{c.enrollment_ends_on} and your team still needs #{needed} more member#{ "s" if needed > 1} to be official. <a href=\"/#/team\">Invite</a> or remind your co-workers to join today!", :from => team.leader, :key => "enrollment_ends_#{c.id}")
        end
      }
    end
  end

end