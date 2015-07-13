class Task

  def self.execute_daily_tasks(send_emails=false)
    body = ""
    Promotion.find(:all, :conditions => "subdomain = 'www'").each do |p|
      begin
        body<<"===================================================================================================\n"
        send_daily_emails(p) if send_emails && ![0,6].include?(Date.today.wday) # Use the && condition if you want skip sending emails for certain days. See SkipDays in tip.rb.
        unless p.current_competition.nil?
          delete_pending_teams(p)
          team_notifications(p)
        end
      rescue Exception => ex
        body<<"ERROR processing promotion #{p.subdomain} #{ex.to_s}\n#{ex.backtrace.join("\n")}"
      end
      body<<"===================================================================================================\n\n\n\n"
    end
    self.mail_kp_verification()
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


  def self.mail_kp_verification
    require 'ftools'

    unless User.connection.tables.include?('kp_verification')
      User.connection.execute "create table kp_verification (user_id int,create_date date)"
      User.connection.execute "create index by_user_id on kp_verification(user_id)"
    end

    #Update everyone
    Profile.do_nuid_verification

    promotion_ids = [1];

    # put everyone there that isn't there already and wants to be
    now=Date.today.strftime('%Y-%m-%d')
      User.connection.execute "
      insert into kp_verification 
      select users.id, now()
      from users 
      left join locations locationLow on locationLow.id = users.location_id
      left join locations locationTop on locationTop.id = users.top_level_location_id
      left join profiles on profiles.user_id = users.id
      where nuid_verified = 0 and profiles.is_reward_participant = 1
      and users.promotion_id in (#{promotion_ids.join(',')})  and email not like '%hesonline%' 
      and email not like '%hesapps.com%'
      and users.id not in (Select user_id from kp_verification);"

    # get everyone that was just put there, break them into groups

    #Master List (includes EVERYBODY including NOT SURE)
    #Julie.M.Boutell@kp.org
    #self.do_kp_verification(now,"1=1","MASTER",['bobb@hesonline.com','jessicai@hesonline.com','rebeccaf@hesonline.com','Julie.M.Boutell@kp.org'],true)
    self.do_kp_verification(now,"1=1","MASTER",['bobb@hesonline.com', 'julie.m.boutell@kp.org', 'rebeccah@hesonline.com', 'alexh@hesonline.com'],true)
  end

  def self.do_kp_verification(date,clause,report_name,recipients,send_email)
    path="#{Rails.root}/export/verification"
    fn="#{path}/#{report_name}-#{date}.csv"
    File.makedirs(path)
    begin
      Rails.logger.info "selecting participants for #{report_name}"
      # get the data
        # promotion_ids = db == 'thrive_ee' ? [1,15,21,22,23,24] : db == 'kpmixitup' ? [1,7,8,13] : [1];
        promotion_ids = [1];

        sql = "Select
        locationTop.name `Region`,
        locationLow.name `Entity`,
        users.altid `NUID`,
        profiles.first_name `First Name`,
        profiles.last_name `Last Name`,
        users.email `Email`,
        '' `Eligible?`, 
        '' `Comments`
        from kp_verification
        left join users on users.id = kp_verification.user_id
        left join locations locationLow on locationLow.id = users.location_id
        left join locations locationTop on locationTop.id = users.top_level_location_id
        left join profiles on profiles.user_id = users.id
        where kp_verification.create_date = '#{date.to_s}'
        and users.promotion_id in (#{promotion_ids.join(',')}) and #{clause} 
        order by Region,Entity,NUID"
        puts sql

        rows=User.connection.select_all sql
        puts "#{rows.size} participants found for #{report_name}"

      # prep the directory, look for existing, etc
      if File.exists?(fn)
        puts "#{fn} exists"
        bak_fn="#{fn}~#{File.mtime(fn).strftime('%Y%m%d%H%M%S')}.csv"
        File.move(fn,bak_fn)
        puts "#{fn} renamed to #{bak_fn}"
      end

      # write the file
      puts "writing file #{fn} for #{report_name}"
      FCSV.open(fn,'w') do |f|
        f << ['Region','Entity','NUID','First Name','Last Name','Email','Eligible?','Comments']
        rows.each do |row|
          f << [row['Region'],row['Entity'],row['NUID'],row['First Name'],row['Last Name'],row['Email'],row['Eligible?'],'']
        end
      end
      puts "wrote file #{fn} for #{report_name}"

      # email the file
      if send_email
        puts "emailing #{fn} to #{recipients.join(',')} for #{report_name}"
        p=Promotion.find(1)
        fs = rows.size > 0 ? [fn] : []
        GoMailer.kp_verification(p, "#{p.subdomain}.#{DomainConfig::DomainNames.first}", fs, recipients, "Employment Verification for #{report_name}").deliver!
        puts "sent #{fn} to #{recipients.join(',')} for #{report_name}"
      else
        puts "send_email set to false for #{report_name}, not sending email"
      end
      return rows.size > 0 ? fn : nil
    rescue Exception => ex
      puts "exception occurred while processing #{report_name}\n#{ex.to_s}\n#{ex.backtrace.join("\n")}"
    end
    return nil
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
