class EligibilitiesController < ApplicationController
  wrap_parameters :eligibility
  authorize :validate, :public
  authorize :index, :show, :create, :update, :destroy, :upload, :coordinator

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.eligibilities : Eligibility
  end
  private :set_sandbox

  def index  
    sql = "SELECT id, first_name, last_name, email, identifier, user_id
          FROM eligibilities
          WHERE eligibilities.promotion_id = #{@promotion.id};"
    rows = ActiveRecord::Base.connection.select_all(sql)
    return HESResponder(rows)
  end

  def validate
    return HESResponder("Must provide eligibility ID.", "ERROR") unless !params[:identifier].nil? && !params[:identifier].strip.empty?
    eligibility = @SB.find_by_identifier(params[:identifier]) rescue nil
    return HESResponder("Eligibility", "NOT_FOUND") if !eligibility
    if eligibility.user_id.nil?
      return HESResponder(eligibility)
    else
      return HESResponder("Eligibility identifier already in use.", "ERROR")
    end
  end

  def show
    eligibility = @SB.find(params[:id]) rescue nil
    return HESResponder("Eligibility", "NOT_FOUND") if !eligibility
    return HESResponder(eligibility)
  end

  def create
    eligibility = @SB.build(params[:eligibility])
    return HESResponder(eligibility.errors.full_messages, "ERROR") if !eligibility.valid?
    Eligibility.transaction do
      eligibility.save!
    end
    return HESResponder(eligibility)
  end

  def update
    eligibility = @SB.find(params[:id]) rescue nil
    return HESResponder("Eligibility", "NOT_FOUND") if !eligibility
    Eligibility.transaction do
      eligibility.update_attributes(params[:eligibility])
    end
    return HESResponder(eligibility.errors.full_messages, "ERROR") if !eligibility.valid?
    return HESResponder(eligibility)
  end

  def destroy
  	eligibility = @SB.find(params[:id]) rescue nil
    return HESResponder("Eligibility", "NOT_FOUND") if !eligibility 
    Eligibility.transaction do
      eligibility.destroy
    end
  	return HESResponder(eligibility)
  end




  def files
    dir = "#{RAILS_ROOT}/eligibility/#{@promotion.id}-#{@promotion.name}/*.csv"
    @files = Dir.glob(dir).map {|f| [File.basename(f), File.mtime(f)]}
  end
  
  def downloadeligibilityfile
    # don't trust the request.  strip the file name out, and put the proper dir on it
    file = "#{RAILS_ROOT}/eligibility/#{@promotion.id}-#{@promotion.name}/#{File.basename(params[:file])}"
    send_file file, :type => "text/csv"
  end
  
  def deleteeligibilityfile
    # don't trust the request.  strip the file name out, and put the proper dir on it
    file = "#{RAILS_ROOT}/eligibility/#{@promotion.id}-#{@promotion.name}/#{File.basename(params[:file])}"
    File.delete file

    redirect_to :action=>:files
  end
  
  def processeligibilityfile
    lrpf = "/var/nice_passenger/long_running_pids/#{Process.pid}"                                                                                                                                                              
    begin                                                                                                                                                                                                                      
      File.open(lrpf,'w'){|f|f.puts Process.pid} if RAILS_ENV=='production'                                                                                                                                                    

      # don't trust the request.  strip the file name out, and put the proper dir on it
      file = "#{RAILS_ROOT}/eligibility/#{@promotion.id}-#{@promotion.name}/#{File.basename(params[:file])}"
      Eligibility.transaction do
        row_count = 0
        errors = []
        begin
          FCSV.foreach(file) do |row|
            if row_count > 0
              e = @promotion.eligibilities.find_by_identifier(row[0])
              update_hash = {:identifier=> row[0],:first_name=>row[1],:last_name => row[2],:email=>row[3]}
              @promotion.custom_eligibility_fields.each do |cef|
                update_hash[cef.eligibility_column_name.to_sym] = row[cef.file_position]
              end
              unless e.nil?
                e.update_attributes(update_hash)
              else
                e = @promotion.eligibilities.create(update_hash)
              end
              errors << "Errors for row \##{row_count}:<br />&nbsp;&nbsp;#{e.errors.full_messages.join("<br />&nbsp;&nbsp;")}" unless e.errors.size == 0
            end
            row_count +=1
          end
          err_msg = errors.size > 0 ? ":<br /> #{errors.join('<br />')}" : "."
          flash[:notice] = "Processed #{row_count-1} rows. #{errors.size} errors detected #{err_msg}"
        end
      end
    ensure
      File.delete(lrpf) if RAILS_ENV=='production' && File.exists?(lrpf)
    end
    redirect_to :action=>:files
  end
  
  def upload
    return HESResponder("Must provide file path.", "ERROR") unless !params[:file].nil? && !params[:file].empty?
    params[:file][0] = '' if params[:file][0] == '/'
    basename = File.basename(file)
    file = FilesController::SECURE_DIR_PATH.join(basename)
    return HESResponder("File is invalid.", "ERROR") unless File.exist?(file)

    dir = Rails.root.join("eligibility")
    Dir.mkdir(dir) unless File.exist?(dir)
    dir = Rails.root.join("eligibility/#{@promotion.id}")
    Dir.mkdir(dir) unless File.exist?(dir)

    if basename.upcase.index /.CSV$/
      newfilepath = File.join(dir, name)
      File.open(newfilepath, "wb") {|f| f.write(file.read)}
      return HESResponder()
    else
      return HESResponder("File must be CSV format.", "ERROR")
    end
  end
  
end
