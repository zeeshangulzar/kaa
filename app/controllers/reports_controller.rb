class ReportsController < ApplicationController
  respond_to :json

  before_filter :get_promotion
  before_filter :set_report, :only => [:run, :show]
  
  authorize :index, :show, :run, :coordinator

  authorize :create, :update, lambda {|user, promotion, report, params| 
    return true if user.master?
    return false if promotion.default?

    if params[:action] == 'create'
      params[:report][:report_type] == 'Simple'
    else
      report.report_type == 'Simple' && (params[:report][:report_type].nil? || params[:report][:report_type] == 'Simple')
    end
  }

  authorize :destroy, lambda {|user, promotion, report, params| user.master? || (user.coordinator? && !report.is_default_path?)}

  def get_promotion
    @promotion ||= Promotion.find(params[:promotion_id])
    return @promotion
  end

  def set_report
    @report_setup = @promotion.report_setup
    @report ||= @promotion.reports.find(params[:id]) || @promotion.reports.build
    @report.promotionize(@promotion)
  end

  def authorization_parameters
    @promotion = Promotion.find(params[:promotion_id])
    @report ||= @promotion.reports.find(params[:id]) || @promotion.reports.build
    return [@promotion, @report]
  end

  def index
    @reports = Report.find(:all)
    @reports = @reports.concat(@promotion.reports) if @promotion.reports.is_cloned?
    return HESResponder({:data => @reports.as_json, :meta => nil})
  end

  def show
    @report = Report.find(params[:id]) || @promotion.reports.find(params[:id])
    return HESResponder(@report)
  end

  def run
    if @report.report_type == Report::ReportType_SQL
      # prevent non-master from posting SQL
      @report.sql = params[:report][:sql] if @report.new_record? && @user.role == 'Master'
    else
      @result_fields = params[:field].sort{|x, y| x <=> y}.collect{|x| x} if params[:field]
      @report.fields = @result_fields if @result_fields
    end

    hash_filters = []
    if params[:filter]
      params[:filter].each do |filter| 
        hash_filters << {:field => filter[:field], :sign => filter[:sign], :value => filter[:value] || ''}
      end
    end
    @report.filters[:hashes] = hash_filters
    @report.filters[:special] = report_filters_to_special_hash

    # get the data
    begin
      data = @report.get_data
    rescue Exception => err
      if err.message.include?('sensitive')
        return HESResponder("Sensitive information.", "DENIED")
      else
        return HESResponder(err, "ERROR")
      end
    end

    @rows = data.empty? ? [] : data

    respond_to do |wants|
      wants.csv { render :text => @rows.collect{|r|r.to_csv}.join }
      wants.json do
        return HESResponder(@rows)
      end
    end
  end

  def create
    @promotion.reports.clone_default unless @promotion.default?

    # Filters have to be set on hashes key?
    params[:report][:filters] = {:hashes => params[:report][:filters]}
    
    # Set this to true so the coordinator can't accidentally delete a report that they paid us to develop
    params[:report][:created_by_master] = @user.master?

    @report = @promotion.reports.create(params[:report])

    return HESResponder(@report)
  end

  def update

    unless @promotion.default?
      @report = Report.find(params[:id])
      @promotion.reports.clone_default
      @report = @promotion.reports.build(@report.attributes)
      @report.id = nil
    else
      @report = @promotion.reports.find(params[:id])
    end

    # Filters have to be set on hashes key?
    params[:report][:filters] = {:hashes => params[:report][:filters]}
    
    # Set this to true so the coordinator can't accidentally delete a report that they paid us to develop
    params[:report][:created_by_master] = @user.master?

    @report.update_attributes(params[:report])
    return HESResponder(@report)
  end
  
  def destroy
    @report.destroy
    return HESResponder(@report)
  end

  def report_filters_to_special_hash(h = params[:report_filter] || {})
    rh = {}
    
    # r,o,p = @promotion.organization.reseller_id,@promotion.organization_id,@promotion.id
    # if h[:promotion]
    #   r,o,p = h[:promotion].split('/')
    #   r = @promotion.organization.reseller_id unless @user.role==User::Role[:master]
    #   o = @promotion.organization_id unless [User::Role[:master],User::Role[:reseller]].include?(@user.role)
    # end
    # rh[:reseller_id] = r unless r=="*"
    # rh[:organization_id] = o unless o=="*"

    p = @promotion.id
    rh[:promotion_id] = p unless p == "*"
    
    filter_promo = p == @promotion.id ? @promotion : p != "*" ? Promotion.find(p) : nil
    
    rh[:reported_on_min] = params[:min_date] ? Date.parse(params[:min_date]) : [(filter_promo||@promotion).users.entries.minimum(:recorded_on) || Date.today,Date.today].min
    rh[:reported_on_max] = params[:max_date] ? Date.parse(params[:max_date]) : [(filter_promo||@promotion).users.entries.maximum(:recorded_on) || Date.today,Date.today].min
    
    # if filter_promo && filter_promo.flags[:is_location_displayed] && !h[:top_level_location].to_s.strip.empty?
    #   rh[:top_level_location] = h[:top_level_location]
    #   session[:report_filter_top_level_location] = h[:top_level_location]
    # else
    #   # nil this variable if you don't want it to be carried between requests
    #   session[:report_filter_top_level_location] = nil
    # end
    
    # if filter_promo && filter_promo.flags[:is_location_displayed] && !h[:location].to_s.strip.empty?
    #   rh[:location] = h[:location]
    #   session[:report_filter_location] = h[:location]
    # else
    #   # nil this variable if you don't want it to be carried between requests
    #   session[:report_filter_location] = nil
    # end
    
    return rh
  end

  def report_url(report)
    return "/promotions/#{@promotion.id}/reports/#{report.id}"
  end
end
