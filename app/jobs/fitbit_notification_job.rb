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
              Rails.cache.write(cache_key,Time.now,:expires_in=>exp)
              log "Caching data for FitbitUser##{fitbit_user.id} / User##{fitbit_user.user.id} for #{date} for #{exp} seconds (#{pending} jobs in Resque queue)"
            end

            log "Processing notification for FitbitUser##{fitbit_user.id} / User##{fitbit_user.user.id}"
            if fitbit_user.user.active_device == 'FITBIT'
              t1 = Time.now
              FitbitUser.transaction do
                fitbit_user.retrieve_activities_on_date(date)
                log "- retrieved Fitbit data in #{(Time.now-t1).round(3)} seconds", 2
                t1 = Time.now
                notification = fitbit_user.notifications.create :collection_type=>hash['collectionType'], :date=>date, :owner_id=>hash['ownerId'], :owner_type=>hash['ownerType'], :status=>FitbitNotification::Status[:new]

                entry = fitbit_user.user.entries.find(:first, :conditions => {:recorded_on => notification.date})
                fds = FitbitUserDailySummary.find(:first, :conditions => {:fitbit_user_id => fitbit_user.id, :reported_on => notification.date})

                if fds
                  if fds.steps > 0
                    # Only need to deal with an entry if the date is within the logging period of the promotion.  does gokp end???
                    if notification.date >= fitbit_user.user.promotion.starts_on && notification.date <= fitbit_user.user.promotion.ends_on
                      if entry

                        # Update the entry.
                        Entry.transaction do
                          FitbitLogger.update_entry(entry, fitbit_user, fds, true)
                          log "- Updated Entry##{entry.id} for FitbitUser##{fitbit_user.id} #{fitbit_user.encoded_id} -- steps now #{entry.exercise_steps}", 2
                        end
                      else

                        # Create new entry if the date would fall between the promotion's dates.
                        Entry.transaction do
                          entry = FitbitLogger.create_entry(fitbit_user, fds, true)
                          log "- Created Entry##{entry.id} for FitbitUser##{fitbit_user.id} #{fitbit_user.encoded_id} -- steps are #{entry.exercise_steps}", 2
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
end
