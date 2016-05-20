class FitbitNotificationJob
  require 'fitbit_logger'
  @queue = :devices

  def self.log(s, indent = 1)
    msg = "#{Time.now} PID #{$$} #{'  ' * indent}#{s}"
    File.open("#{Rails.root}/log/fitbit_import_control.log", "a") {|f| f.puts msg}
    puts msg
    msg
  end

  def self.log_and_put(s, indent = 1)
    puts log(s, indent)
  end

  def self.log_ex(ex)
    log "#{ex.backtrace.join("\n")}: #{ex.message} (#{ex.class})"
  end

  def self.flag_all_as_exception(fitbit_user_id)
    FitbitNotification.find(:all, :conditions => ["fitbit_user_id = ? and status = ?", fitbit_user_id, FitbitNotification::Status[:new]]).each do |nf|
      nf.update_attributes :status => FitbitNotification::Status[:exception]
    end
  end

  def self.perform(array)
    ActiveRecord::Base.verify_active_connections!
    array.each do |hash|
      start_time = Time.now
      begin
        sid = hash['subscriptionId']
        date = Date.parse(hash['date'])
        key = "#{date}-#{hash['collectionType']}"

        fitbit_user = FitbitUser.where(:id=>sid).first

        if fitbit_user
          if fitbit_user.user
            cache_key = "FitbitUser_#{fitbit_user.id}_#{date.to_s(:db)}"
            last_synced_at = Rails.cache.read(cache_key)
            if last_synced_at
              log "Skipping notification for FitbitUser##{fitbit_user.id} / User##{fitbit_user.user.id} for #{date} because it was last updated at #{last_synced_at}"
              next
            else
              pending = Resque.info[:pending]
              exp = (pending/500.0)
              exp = 15 if exp < 15
              Rails.cache.write(cache_key,Time.now,:expires_in=>exp.seconds)
              log "Caching data for FitbitUser##{fitbit_user.id} / User##{fitbit_user.user.id} for #{date} for #{exp} seconds (#{pending} jobs in Resque queue)"
            end

            log "Processing notification for FitbitUser##{fitbit_user.id} / User##{fitbit_user.user.id}"
            if fitbit_user.user.active_device == 'FITBIT'
              t1 = Time.now
              FitbitUser.transaction do
                
                # 
                begin
                  fitbit_user.retrieve_activities_on_date(date)
                rescue Fitgem::OAuthProblem
                  if fix_broken_token(fitbit_user.user.fitbit_oauth_token.secret)
                    fitbit_user = FitbitUser.find(fitbit_user.id) # need to re-fetch to reinitialize
                    fitbit_user.retrieve_activities_on_date(date)
                  else
                    log "- attempts to fix oauth secret failed", 2
                    flag_all_as_exception fitbit_user.id
                    next # proceed to next hash in array
                  end
                rescue #Error::ConnectionFailed, SocketError
                  hash[:retries] ||= 0
                  hash[:retries] = hash[:retries] + 1
                  #Resque.enqueue_in 1.minute,FitbitNotificationJob,[hash] unless hash[:retries] > 2
                  unless hash[:retries] > 3
                    log "- Short nap", 2
                    sleep(0.1)
                    retry
                  else
                    next
                  end
                end
                # 
                
                log "- retrieved Fitbit data in #{(Time.now-t1).round(3)} seconds", 2
                t1 = Time.now
                notification = fitbit_user.notifications.create :collection_type=>hash['collectionType'], :date=>date, :owner_id=>hash['ownerId'], :owner_type=>hash['ownerType'], :status=>FitbitNotification::Status[:new]

                entry = fitbit_user.user.entries.find(:first, :conditions => {:logged_on => notification.date})
                
                # Find the activity that is synced with Fitbit.
                act = fitbit_user.user.promotion.recording_activities.find(:first, :conditions => "sync_with_device_steps = true")

                if act
                  fds = FitbitUserDailySummary.find(:first, :conditions => {:fitbit_user_id => fitbit_user.id, :reported_on => notification.date})

                  if fds
                    if fds.steps > 0
                      if notification.date >= fitbit_user.user.promotion.starts_on && notification.date <= fitbit_user.user.promotion.ends_on
                        if entry

                          # Update the entry.
                          Entry.transaction do
                            FitbitLogger.update_entry(entry, act, fitbit_user, fds, true)
                            log "- Updated Entry##{entry.id} for FitbitUser##{fitbit_user.id} #{fitbit_user.encoded_id} -- steps now #{fds.steps}", 2
                          end
                        else

                          # Create entry.
                          Entry.transaction do
                            entry = FitbitLogger.create_entry(act, fitbit_user, fds, true)
                            log "- Created Entry##{entry.id} for FitbitUser##{fitbit_user.id} #{fitbit_user.encoded_id} -- steps are #{fds.steps}", 2
                          end
                        end
                      end
                      
                      notification.update_attributes(:status => FitbitNotification::Status[:processed])
                    else
                      log "- FitbitUserDailySummary for #{notification.date} has 0 steps. not logging entry.", 2
                      notification.update_attributes(:status => FitbitNotification::Status[:processed])
                    end                  
                  else
                    log "- FitbitUserDailySummary for #{notification.date} not found", 2
                    notification.update_attributes(:status => FitbitNotification::Status[:exception])
                  end
                else
                  log "- No Activity mapped to Fitbit Steps was found in promotion: #{fitbit_user.user.promotion.subdomain}", 2
                end

                # if fds
                # else
                  # log "- FitbitUserDailySummary for #{notification.date} not found", 2
                  # notification.update_attributes(:status => FitbitNotification::Status[:exception])
                # end
                log "- finished in #{(Time.now-t1).round(3)} seconds", 2
              end
            else
              log "active_device is not FITBIT; it is presently '#{fitbit_user.user.active_device}' -- notification ignored", 2
              flag_all_as_exception fitbit_user.id
            end
          else
            log "FitbitUser##{fitbit_user.id} not tied to user -- User##{fitbit_user.user_id} not found"
            flag_all_as_exception fitbit_user.id
          end
        else
          log "FitbitUser##{row[:fitbit_user_id]} not found"
          flag_all_as_exception row[:fitbit_user_id]
        end
      rescue Exception => ex
        log "ROW EXCEPTION"
        log_ex ex
      end
      log "completed in #{((Time.now - start_time)*1000).round}ms",3
    end
  end

  def self.fix_broken_token(secret)
    log "attempting to fix broken oauth token secret", 3
    fat=FitbitOauthToken.find(:all,:conditions=>{:secret=>secret})
    if fat.size == 1
      if fat.first.user && fat.first.user.fitbit_user
        2.times do |n|
          begin
            fat.first.reload.user.reload.fitbit_user.reload.retrieve_devices
            log "FitbitOauthToken##{fat.first.id} #{n==0 ? 'was just fine' : 'has been fixed'}", 3
            return true
          rescue Fitgem::OAuthProblem
            if n.zero?
              latest_secret = `grep FitbitOauthToken##{fat.first.id} log/oauth_tokens_log.txt | tail -n1 | awk '{print $(NF)}'`.chomp
              unless latest_secret.to_s.strip.empty?
                if latest_secret != fat.first.secret
                  log "FitbitOauthToken##{fat.first.id} will be fixed by changing secret from #{secret} to #{latest_secret}", 3
                  fat.first.update_attributes :secret=>latest_secret
                else
                  log "FitbitOauthToken##{fat.first.id} is already set to the latest secret in the log file", 3
                  break
                end
              else
                log "FitbitOauthToken##{fat.first.id} could not be fixed because the secret was not found in log/oauth_tokens_log.txt", 3
                break
              end
            else
              log "FitbitOauthToken##{fat.first.id} was not fixed after being updated.  Secret changed back to the previous value #{secret}", 3
              fat.first.update_attributes :secret=>secret
            end
          end
        end
      else
        log "FitbitOauthToken##{fat.first.id} is orphaned: it #{fat.first.user ? "belongs to User##{fat.first.user.id}" : 'does not belong to a user'} and #{fat.first.user && fat.first.user.fitbit_user ? "belongs to FitbitUser##{fat.first.fitbit_user.id}" : 'but that user does not have a FitbitUser'}", 3
      end
    elsif fat.empty?
      log "no FitbitOauthToken found with secret #{secret}", 3
    else
      log "multiple FitbitOauthTokens with secret #{secret} found", 3
    end
    false
  end
end
