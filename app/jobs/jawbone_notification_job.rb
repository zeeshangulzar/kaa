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

  def self.flag_all_as(jawbone_user_id,status,event_xids=nil)
    JawboneNotification.find(:all,:conditions=>["jawbone_user_id = ? and status = ?",jawbone_user_id,JawboneNotification::Status[:new]]).each do |nf| 
      if !event_xids || event_xids.include?(nf.event_xid)
        nf.update_attributes :status=>status
      end
    end
  end

  def self.flag_all_as_exception(jawbone_user_id)
    flag_all_as jawbone_user_id,JawboneNotification::Status[:exception]
  end


  def self.validUserTrip(jbu)
    true 
  end

  def self.perform(hash)
    if !hash.empty?
      ActiveRecord::Base.verify_active_connections!
      log "JawboneNotificationJob performing work on #{hash.inspect}"
      begin
            #Process notifications
            begin
              st = Time.now
              processed = {}

              hash.keys.each do |jbu_xid|
              # find the most recent non-orphaned user
              jbu = JawboneUser.find(:last,:conditions=>["xid=? and promotions.id is not null",jbu_xid],:include=>{:user=>[:promotion]})
              unless jbu && jbu.user
                log "- JawboneUser with xid #{jbu_xid} is orphaned",2
                next
              end

              log "Processing JawboneUser##{jbu.id} (#{jbu.user.email rescue 'unknown email'} / #{jbu.xid})",2

              if !jbu.user.promotion.is_active
                # ???  jbu.unsubscribe_from_notifications

                # TODO: Define 'inactive_on'. Any replacement for 'individual_logging_frozen'?
                # log "- promotion went inactive on #{jbu.user.promotion.inactive_on}. unsubscribed from notifications.",2
              else
                HESSecurityMiddleware.set_current_user(jbu.user)
                #STEP 1 - get the requested data from Jawbone
                processing_message = ''
                k = hash[jbu_xid].keys.first
                v = hash[jbu_xid][k]
                dates = []
                event_xids = []
                if k.to_s == 'date'
                  date = Date.parse(v)
                  processing_message = "on #{date}"
                  log "- pulling Jawbone data #{processing_message}",3
                  dates << date
                  jbu.pull_move_for_date(date)
                elsif k.to_s == 'range'
                  dates = v.collect{|s|Date.parse(s)}.sort
                  processing_message = "from #{dates.first} to #{dates.last}"
                  log "- pulling Jawbone data #{processing_message}",3
                  jbu.pull_moves_in_range(dates.first,dates.last)
                elsif k.to_s == 'dates'
                  dates = v.collect{|s|Date.parse(s)}
                  processing_message = "on #{dates.join(',')}"
                  dates.each do |d|
                    log "- pulling Jawbone data for: #{d}",3
                    jbu.pull_move_for_date(d)
                  end
                elsif k.to_s == 'xids'
                  v.each do |mv|
                    log "- pulling Jawbone data for xid: #{mv}",3
                    move = jbu.pull_move_by_xid(mv)
                    if move
                      if move.is_a?(JawboneMoveData)
                        dates << move.on_date
                        processing_message = "on #{dates.first}"
                      else
                        log "- JawboneMoveData was not returned when pulling move by xid #{mv.inspect}     #{move.inspect}",2
                      end
                    else
                      log "- nil returned when pulling move by xid: #{mv.inspect}",2
                    end
                    event_xids << mv
                  end
                else
                  log "- item '#{k}' not understood: #{v.inspect}",2
                end 

                log "- user belongs to promotion: #{jbu.user.promotion.subdomain rescue 'unknown'} and has #{dates.size} days to update #{processing_message}",3

                #STEP 2 - apply the requested data to the user's entries
                begin
                  processed[jbu.id] ||= []
                  if jbu.user 
                    if jbu.user.active_device == 'JAWBONE'
                      otherJbus = JawboneUser.find(:all, :conditions => "id <> #{jbu.id} AND xid = '#{jbu.xid}'")
                      allJbus = [jbu,otherJbus].flatten.uniq
                      allJbus.each_with_index do |this_jbu,jbu_index|
                        if this_jbu
                          if jbu_index > 0
                            log "- additional user #{this_jbu.user.contact.email} belongs to promotion: #{this_jbu.user.promotion.subdomain rescue 'unknown'} and has #{dates.size} days to update #{processing_message}",3
                          end
                          if !this_jbu.user.promotion
                            # this_jbu.user belongs to a deleted promotion -- silently skip
                            next
                          elsif !this_jbu.user.promotion.is_active
                            log "- promotion went inactive on #{this_jbu.user.promotion.inactive_on}.",4
                          # TODO: Any replacement for 'individual_logging_frozen'?
                          elsif validUserTrip(this_jbu)
                            dates.each do |date|
                              jmd = allJbus.first.jawbone_move_datas.find(:first,:conditions=>{:on_date=>date})
                              if jmd
                                if jmd.steps > 0
                                  User.transaction do 
                                    JawboneLogger.log_entry(jmd.date,jbu,jmd,true)
                                  end
                                else
                                  log "- steps are 0, not importing #{date}",4
                                end
                              else
                                log "- jawbone_move_data not found for #{date}",4
                              end
                            end
                            this_jbu.update_attributes :last_sync => Time.now.to_i
                            if event_xids.empty?
                              flag_all_as jbu.id,JawboneNotification::Status[:processed]
                            else
                              flag_all_as jbu.id,JawboneNotification::Status[:processed],event_xids
                            end
                          else
                            log "- user has not chosen a map.  data will be held.",4
                            flag_all_as jbu.id,JawboneNotification::Status[:hold]
                          end
                        end
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
                  raise
                end
              end
            end
            rescue => ex
              log "GLOBAL EXCEPTION"
              log_ex ex
              ActiveRecord::Base.connection.disconnect!
              ActiveRecord::Base.connection.reconnect!
            end
      rescue Exception => ex
        log_ex ex
      ensure
        HESSecurityMiddleware.set_current_user(nil)
      end
    end
  end
end