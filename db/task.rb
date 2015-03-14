class Task

  def self.execute_daily_tasks(send_emails=false)
    Promotion.find(:all, :conditions => "is_active = true").each do |p|
      begin
        body<<"===================================================================================================\n"
        send_daily_emails(p) if send_emails && ![0,6].include?(Date.today.wday) # Use the && condition if you want skip sending emails for certain days. See SkipDays in tip.rb.
        trigger_evaluations(p)
      rescue Exception => ex
        body<<"ERROR processing promotion #{p.subdomain} #{ex.to_s}\n#{ex.backtrace.join("\n")}"
      end
    body<<"===================================================================================================\n\n\n\n"
    end
    send_email(body,"Daily Tasks for #{Date.today}")
  end
  
  def self.send_daily_emails(p)
      if ![0,6].include?(p.current_date.wday)
        queue = true#true unless IS_STAGING #|| RAILS_ENV=='development'

        users = p.users.includes(:profile).where("profiles.started_on <= '#{p.current_date}'")

        day = Tip.get_day_number_from_date(p.current_date)

        mails=[]

        users.each{ |u|

          what_to_send = 'daily_email'

          p.email_reminders.each{|reminder|
            if ( u.last_login < (p.current_time - (reminder.days).days) ) && !u.email_reminders.include?(reminder)
              what_to_send = 'reminder'
              email_reminder = reminder
              break
            end
          }

          if p.current_date.wday == 1 && !u.flags[:allow_daily_emails_monday]
            what_to_send = 'nothing'
          elsif p.current_date.wday != 1 && !u.flags[:allow_daily_emails_all_week]
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




  def self.send_email(b,s)
    require 'mailfactory'
    f='Fast Track to Fitness <admin@gofasttracktofitness.com>'
    t='developer@hesonline.com' 
    smtp = Net::SMTP.new('email.hesonline.com', 25)
    smtp.start('email.hesonline.com')

    mail = MailFactory.new()
    mail.to = t 
    mail.from = f 
    mail.subject = s

    mail.text = b 

    smtp.send_message mail.construct, f, t 
    smtp.finish()
  end

  def self.mail_fulfillment
    puts "STARTING fulfillment #{Time.now}"
    Order.connection.execute "alter table orders add fulfilled_on date" unless Order.column_names.include?('fulfilled_on')
    now=Date.today.strftime('%Y-%m-%d')

    sql = "update orders set fulfilled_on = '#{now}' where fulfilled_on is null"

    User.connection.execute sql

    users = User.find(:all,:joins=>"inner join orders on orders.user_id = users.id and orders.fulfilled_on = '#{now}'",:include=>{:contact=>:address})
    puts "  - #{users.size} users/orders to fulfill #{Time.now}"

    export = {}
    users.each do |user|
      key = user.promotion.subdomain

      export[key] ||= [['First Name','Last Name','Address','Address Line 2','City','State','Zip Code','Payment Type','Package','Shirt Size']]

      arr = [user.contact.first_name,user.contact.last_name]

      if user.contact.address
        arr << [user.contact.address.line1,user.contact.address.line2,user.contact.address.city,user.contact.address.state_province,user.contact.address.postal_code]
      else
        arr << ['missing','missing','missing','missing','missing']
      end

      arr << user.fitbit_registration_type

      o = user.orders.first
      if o
        arr << [o.package_key,o.additional_1]
      end

      export[key] << arr.flatten
    end

    files=[]
    path="#{RAILS_ROOT}/export/fulfillment"
    File.makedirs(path)

    export.keys.each do |k|
      fn="#{path}/#{k}-#{now}.csv"
      files<<fn
      FCSV.open(fn,'w') do |f|
        export[k].each {|arr| f<<arr}
      end
    end

    unless files.empty?
      puts "  - emailing the following files"
      files.each do |fn|
        puts "    #{fn}"
      end
    else
      puts "  - 0 files to email"
    end

    HesMailer.deliver_fulfillment(Promotion.first, "dashboard.gofasttracktofitness.com", files, !files.empty?)
    puts "FINISHED fulfillment #{Time.now}"
  end

end



