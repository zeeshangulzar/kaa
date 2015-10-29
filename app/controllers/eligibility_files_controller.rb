class EligibilityFilesController < ApplicationController
  authorize :index, :show, :create, :update, :destroy, :process, :coordinator
  authorize :start_job, :cancel_job, :download, :master

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.eligibility_files : EligibilityFile
  end
  private :set_sandbox
  
  def index  
    return HESResponder(@SB.all)
  end

  def show
    eligibility_file = @SB.find(params[:id]) rescue nil
    return HESResponder("Eligibility File", "NOT_FOUND") if !eligibility_file
    return HESResponder(eligibility_file)
  end

  def create
    eligibility_file = @SB.new(params[:eligibility_file])
    return HESResponder("Must provide file path.", "ERROR") unless !params[:eligibility_file][:filename].nil? && !params[:eligibility_file][:filename].empty?
    params[:eligibility_file][:filename][0] = '' if params[:eligibility_file][:filename][0] == '/'
    basename = File.basename(params[:eligibility_file][:filename])
    file = FilesController::SECURE_DIR_PATH.join(basename)
    return HESResponder("File is invalid.", "ERROR") unless File.exist?(file)
    return HESResponder(eligibility_file.errors.full_messages, "ERROR") if !eligibility_file.valid?

    dir = Rails.root.join("eligibility")
    Dir.mkdir(dir) unless File.exist?(dir)
    dir = Rails.root.join("eligibility/#{@promotion.id}")
    Dir.mkdir(dir) unless File.exist?(dir)

    if basename.upcase.index /.CSV$/
      newfilepath = File.join(dir, basename)
      File.open(newfilepath, "wb") {|f| f.write(file.read)}
      eligibility_file.filename = basename
      EligibilityFile.transaction do
        eligibility_file.save!
      end
      return HESResponder(eligibility_file)
    else
      return HESResponder("File must be CSV format.", "ERROR")
    end
  end

  def update
    eligibility_file = @SB.find(params[:id]) rescue nil
    return HESResponder("Eligibility File", "NOT_FOUND") if !eligibility_file
    EligibilityFile.transaction do
      eligibility_file.update_attributes(params[:eligibility_file])
    end
    return HESResponder(eligibility_file.errors.full_messages, "ERROR") if !eligibility_file.valid?
    return HESResponder(eligibility_file)
  end

  def destroy
  	eligibility_file = @SB.find(params[:id]) rescue nil
    return HESResponder("Eligibility File", "NOT_FOUND") if !eligibility_file
    EligibilityFile.transaction do
      eligibility_file.destroy
    end
  	return HESResponder(eligibility_file)
  end

  def start_job
    eligibility_file = @SB.find(params[:eligibility_file_id]) rescue nil
    return HESResponder("Eligibility File", "NOT_FOUND") if !eligibility_file
    queue_process = eligibility_file.queue_process
    if queue_process[:errors]
      return HESResponder(queue_process[:errors], "ERROR")
    end
    return HESResponder(queue_process)
  end

  def download
    eligibility_file = EligibilityFile.find(params[:eligibility_file_id]) rescue nil
    return HESResponder("Eligibility File", "NOT_FOUND") if !eligibility_file
    data = File.read(eligibility_file.filepath)
    send_data(data, :filename => eligibility_file.filename, :type => "text/csv")
  end

end
