class ProcessEligibilityFile
  @queue = :eligibility

  def self.log(s, indent = 1)
    msg = "#{Time.now} PID #{$$} #{'  ' * indent}#{s}"
    File.open("#{Rails.root}/log/eligibilities.log", "a") {|f| f.puts msg}
    puts msg
    msg
  end

  def self.log_and_put(s, indent = 1)
    puts log(s, indent)
  end

  def self.log_ex(ex)
    log "#{ex.backtrace.join("\n")}: #{ex.message} (#{ex.class})"
  end

  def self.perform(eligibility_file_id)
    ActiveRecord::Base.verify_active_connections!
    eligibility_file = EligibilityFile.find(eligibility_file_id) rescue nil
    if !eligibility_file
      log "Could not find eligibility file with id of #{eligibility_file_id}"
    else
      eligibility_file.process
    end
  end

end
