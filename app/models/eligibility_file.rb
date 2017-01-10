class EligibilityFile < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :filename, :total_rows, :rows_processed, :status, :created_at, :any_user
  attr_accessible :promotion_id, :filename, :total_rows, :rows_processed, :status, :created_at, :updated_at
  
  belongs_to :promotion
  
  validates_presence_of :promotion_id, :filename

  STATUS = {
    :new        => 'new',
    :processing => 'processing',
    :processed  => 'processed',
    :canceled   => 'canceled',
    :deleted    => 'deleted'
  }

  before_save :set_defaults

  def set_defaults
    self.status ||= EligibilityFile::STATUS[:new]
    self.rows_processed ||= 0
    self.total_rows ||= self.get_total_rows
  end

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

  def save_path
    dir = Rails.root.join("eligibility")
    Dir.mkdir(dir) unless File.exist?(dir)
    dir = Rails.root.join("eligibility/#{self.promotion_id}")
    Dir.mkdir(dir) unless File.exist?(dir)
    return Rails.root.join("eligibility/#{self.promotion_id}")
  end

  def filepath
    return self.save_path.join(self.filename)
  end

  def queue_process
    if self.promotion.eligibility_files.where(:status => EligibilityFile::STATUS[:processing]).count > 0
      return {:errors => ['An eligibility file is currently processing for this promotion.']}
    else
      self.update_attributes(:status => EligibilityFile::STATUS[:processing])
      Resque.enqueue(ProcessEligibilityFile, self.id)
      return self.reload
    end
  end

  def get_total_rows
    row_count = `wc -l "#{self.filepath}"`.strip.split(' ')[0].to_i
    return row_count
  end

  def process
    self.connection.execute("UPDATE eligibility_files SET status = '#{EligibilityFile::STATUS[:processing]}', updated_at = '#{self.promotion.current_time.to_formatted_s(:db)}' WHERE id = #{self.id}")
    require 'fileutils'
    file = self.filepath
    row_index = 0
    @cols = []
    @errors = []
    @die = false
    Eligibility.transaction do
      FasterCSV.foreach(filepath) do |row|
        if @die
          self.kill_processing
        end
        self.process_csv_row(row, row_index)
        # for testing...
        # sleep 1
        row_index += 1
        if (row_index == self.total_rows - 10) || (row_index % 20 == 0)
          Thread.new do
            if self.reload && self.status == EligibilityFile::STATUS[:canceled]
              @die = true
            end
            ActiveRecord::Base.connection.execute("UPDATE eligibility_files SET rows_processed = #{row_index.to_s}, updated_at = '#{self.promotion.current_time.to_formatted_s(:db)}' WHERE id = #{self.id}")
          end
        end
      end
      self.connection.execute("UPDATE eligibility_files SET status = '#{EligibilityFile::STATUS[:processed]}', updated_at = '#{self.promotion.current_time.to_formatted_s(:db)}' WHERE id = #{self.id}")
    end
  end

  def process_csv_row(row, row_index)
    if row_index == 0
      row.size.times do |t|
        if self.promotion.eligibility_fields.include?(row[t])
          @cols[t] = row[t]
        end
      end
    end
    if (row_index == 0 && @cols.empty?) || row_index > 0
      @cols = self.promotion.eligibility_fields if @cols.empty?
      eligibility = self.promotion.eligibilities.new
      @cols.each_with_index{ |col, index|
        next if row[index].to_s.strip.empty?
        eligibility.send("#{col}=", row[index])
      }
      if !eligibility.valid?
        @errors << "Errors for row \##{row_index}:<br />&nbsp;&nbsp;#{eligibility.errors.full_messages.join("<br />&nbsp;&nbsp;")}"
      else
        eligibility.save!
        EligibilityFile::log("Eligibility saved for: #{eligibility.inspect}")
      end
    end
  end

  def kill_processing
    Thread.new do
      ActiveRecord::Base.connection.execute("UPDATE eligibility_files SET rows_processed = 0, updated_at = '#{self.promotion.current_time.to_formatted_s(:db)}' WHERE id = #{self.id}")
    end
    EligibilityFile::log("Eligibility file processing canceled.")
    raise ActiveRecord::Rollback
  end

end
