class JawboneNotificationJob
  require 'jawbone_logger'
  @queue = :devices

  ##########################################################################
  # Process Jawbone Notifications
  ##########################################################################

  def self.log(s,indent=1)
    msg = "#{Time.now} #{'  ' * indent}#{s}"
    File.open("#{Rails.root}/log/jawbone_import.log","a") {|f|f.puts msg}
    msg
  end

  def self.log_and_put(s, indent=1)
    puts log(s, indent)
  end

  def self.log_ex(ex)
    log "#{ex.backtrace.join("\n")}: #{ex.message} (#{ex.class})"
  end

  def self.flag_all_as_exception(jawbone_user_id)
    JawboneNotification.find(:all,:conditions=>["jawbone_user_id = ? and status = ?",jawbone_user_id,JawboneNotification::Status[:new]]).each do |nf| 
      nf.update_attributes :status=>JawboneNotification::Status[:exception]
    end
  end

  def self.validUserTrip(jbu)
    true 
  end

  def self.perform(user_xids)
    ActiveRecord::Base.verify_active_connections!
    log "JawboneNotificationJob performing work on #{user_xids.inspect}"
    begin
          #Process notifications
          begin
            st = Time.now
            processed = {}

            in_clause = user_xids.collect{|x|User.sanitize(x)} 
            jbus = JawboneUser.find(:all,:include=>:jawbone_notifications,:conditions=>"xid in (#{in_clause}) and jawbone_notifications.status = '#{JawboneNotification::Status[:new]}'", :order=>'jawbone_notifications.created_at asc')
            jbus.each do |jbu|
              begin
                  processed[jbu.id] ||= []
                if jbu.user 
                  if jbu.user.active_device == 'JAWBONE'
                    otherJbus = JawboneUser.find(:all, :conditions => "id <> #{jbu.id} AND xid = '#{jbu.xid}'")
                    notifications = jbu.jawbone_notifications
                    log "Processing #{notifications.size} notifications for JawboneUser##{jbu.id} (#{jbu.user.email rescue 'unknown email'} / #{jbu.xid}) from #{notifications.first.created_at} to #{notifications.last.created_at}",2
                    log "- user belongs to promotion: #{jbu.user.promotion.subdomain} and has #{notifications.size} days to update",3
                    lastSync = jbu.last_sync.nil? ? 999.hours.ago : Time.at(jbu.last_sync)
                    if lastSync < 1.hour.ago
                      jbu.pull_moves_since_last_sync(2)
                      jbu.jawbone_move_datas.find(:all, :conditions => "on_date > '#{(Date.today - 2)}'", :order => 'on_date desc').each do |jawMoveData|

                        if validUserTrip(jbu)
                          JawboneLogger.log_entry(jawMoveData.date,jbu,jawMoveData,true)
                          jbu.update_attributes :last_sync => Time.now.to_i
                        end
                      end
                    end
                    notifications.each_with_index do |notification,i|
                      #unless jbu.user.promotion.individual_logging_frozen?
                      #don't import data for  duplicate event_xid
                        unless processed[jbu.id].include?(notification.event_xid)
                          begin
                            processed[jbu.id] << notification.event_xid

                            #Pull Data from Jawbone
                            log "- getting event xid : #{notification.event_xid}", 3
                            jmd = jbu.pull_move_by_xid(notification.event_xid)

                            if jmd 
                              #DuplicateIfLogic1
                              if validUserTrip(jbu)
                                Entry.transaction do
                                  entry = JawboneLogger.log_entry(jmd.date,jbu,jmd,true)

                                  # Other users for the application with the same JAWBONE XID. Notifications only get mapped
                                  # to the last JawboneUser created per xid. Most likely these are done promotions, but 
                                  # it's possible they are still going OR used by QA/DEV
                                  otherJbus.each do |otherJbu|
                                    if otherJbu.user
                                      JawboneLogger.log_entry(jmd.date,otherJbu,jmd,true)
                                    else
                                      log "JawboneUser##{otherJbu.id} does not have a User associated with it", 1
                                    end
                                  end 

                                  notification.update_attributes :status=>JawboneNotification::Status[:processed]
                                end
                              else
                                log "- user has not chosen a map.  data will be held.",3
                                # TODO:  update the FITBIT notification message so the user knows to choose a map
                                notification.update_attributes :status=>JawboneNotification::Status[:hold]
                              end
                            else
                              log "- JawboneMoveData for notification: #{notification.id} with event_xid: #{notification.event_xid} not found",3
                            end
                          rescue => ex
                            log "NOTIFICATION EXCEPTION"
                            log_ex ex
                            notification.update_attributes :status=>JawboneNotification::Status[:exception]
                          end
                        else
                          log "- already processed #{notification.event_xid}.",3
                          notification.update_attributes :status=>JawboneNotification::Status[:processed]
                        end
                      #else
                      #  log "- Individual logging frozen for promotion #{jbu.user.promotion_id}.",2
                      #  notification.update_attributes :status=>JawboneNotification::Status[:hold]
                      #end
                    end
                  else
                    log "JawboneUser##{jbu.id} does not have active_device = 'JAWBONE' -- User##{jbu.user_id} active_device is '#{jbu.user.active_device}'",2
                    flag_all_as_exception jbu.id
                  end
                else
                  log "JawboneUser##{jbu.id} not tied to user -- User##{jbu.user_id} not found",2
                  flag_all_as_exception jbu.id
                end
              rescue => ex
                log "ROW EXCEPTION"
                log_ex ex
              end
            end #end each jbu
          rescue => ex
            log "GLOBAL EXCEPTION"
            log_ex ex
            ActiveRecord::Base.connection.disconnect!
            ActiveRecord::Base.connection.reconnect!
          end
    rescue Exception => ex
      log_ex ex
    end
  end
end
