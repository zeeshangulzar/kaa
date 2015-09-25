class Task

  def self.execute_daily_tasks(send_emails = false, single_email = nil)
    body = ""
    Promotion.find(:all, :conditions => "subdomain <> 'www' AND is_active = 1 AND ends_on >= '#{Date.today.to_s(:db)}'").each do |p|
      begin
        body<<"===================================================================================================\n"
        send_daily_emails(p, single_email) if send_emails && ![0,6].include?(Date.today.wday) # Use the && condition if you want skip sending emails for certain days. See SkipDays in tip.rb.
        unless p.current_competition.nil?
          delete_pending_teams(p)
          team_notifications(p)
        end
      rescue Exception => ex
        body<<"ERROR processing promotion #{p.subdomain} #{ex.to_s}\n#{ex.backtrace.join("\n")}"
      end
      body<<"===================================================================================================\n\n\n\n"
    end
    GoMailer.daily_tasks(body).deliver!
  end
  
  def self.send_daily_emails(p, single_email = nil)
    if ![0,6].include?(p.current_date.wday)
        queue = true#true unless IS_STAGING #|| RAILS_ENV=='development'
        users = p.users.includes(:profile).where("profiles.started_on <= '#{p.current_date}'")
        if !single_email.nil?
          users = users.where(:email => single_email)
          queue = false
        end

        day = Tip.get_day_number_for_promotion(p)
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
          tag = "h4h-#{Date.today.strftime('%Y%m%d')}-daily-email-#{p.id}-#{p.subdomain}"
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
        unless team.leader.notifications.find(:first, :conditions => ["`key` = :key", {:key => "enrollment_ends_#{c.id}"}]) || needed < 1
          team.leader.notify(team.leader, "Enrollment Ends Soon", "Team enrollment ends on #{c.enrollment_ends_on} and your team still needs #{needed} more member#{ "s" if needed > 1} to be official. <a href=\"/#/team\">Invite</a> or remind your co-workers to join today!", :from => team.leader, :key => "enrollment_ends_#{c.id}")
        end
      }
    end
  end

  def self.delete_pending_teams(p)
    c = p.current_competition
    return unless c
    if (c.enrollment_ends_on - p.current_date < 0)
      emails = []
      c.teams.pending.each{ |team|
        team.team_members.each{|team_member|
          emails << team_member.user.email
        }
        team.update_attributes(:status => Team::STATUS[:deleted])
      }
      subject = "Team enrollment has ended"
      message = "Team enrollment has ended and unfortunately your team did not have minimum number of participants to qualify for the competition (#{c.team_size_min} min.). Your team has been removed but you can still follow the action <a href='https://#{promotion.subdomain + '.' + DomainConfig::DomainNames.first}/#/team'>here</a>."
      Resque.enqueue(GenericEmail, emails, subject, message, nil, p) unless emails.empty?
    end
  end

end
