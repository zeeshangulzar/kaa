#copied from FitbitLogger... basically just changed some references and notification KEY
class JawboneLogger
  def self.log_entry(recorded_on,jbu,jmd,write_to_log=false)
    entry = jbu.user.entries.find(:first,:conditions=>{:recorded_on => recorded_on}) || jbu.user.entries.build(:recorded_on => recorded_on)
    verb = entry.new_record? ? 'Created' : 'Updated'

    entry.exercise_steps = jmd.steps
    entry.updated_at = Time.now.utc

    if entry.save
      log "- updated Entry##{entry.id} on: #{entry.recorded_on}; steps is now #{entry.exercise_steps}", 3 if write_to_log
      $redis.publish('jawboneEntrySaved', entry.to_json)
    else
      log "- FALSE returned when updating Entry##{entry.id} on: #{entry.recorded_on}", 3 if write_to_log
      log "- validation errors:  #{entry.errors.full_messages.join(',')}", 4 if write_to_log
    end

    # Find the user's Jawbone notification.
    user_notification = jbu.user.notifications.find_by_key('JAWBONE') || jbu.user.notifications.build(:key=>'JAWBONE')
    
    # Date and time Jawbone data was synced.
    dt = jbu.user.promotion.current_date.strftime("%B %e")
    tm = jbu.user.promotion.current_time.strftime("%I:%M %P %Z").gsub(/^0/, '')

    user_notification.update_attributes :message=>"Your UP/UP24 was synchronized with #{Constant::AppName} on #{dt} at #{tm}"

    return entry
  end

  def self.log(s,indent=1)
    msg = "#{Time.now} #{'  ' * indent}#{s}"
    File.open("#{Rails.root}/log/jawbone_import.log","a") {|f|f.puts msg}
    #puts msg
  end
end
