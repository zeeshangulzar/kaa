class ReportJoinsController < ApplicationController
  respond_to :json
  wrap_parameters :report_join, :include => [:alias, :childof, :parentof, :nest_level, :sql]
  before_filter :get_report_setup

  authorize :index, :coordinator
  
  def get_report_setup
    @promotion = Promotion.find(params[:promotion_id])
    @report_setup = @promotion.report_setup
  end
  private :get_report_setup
  
  # GET /report_joins
  # GET /report_joins.xml
  def index
    @report_joins = @report_setup.joins

    respond_with @report_joins
  end

  # POST /report_joins
  # POST /report_joins.xml
  def create
    @report_join = @report_setup.joins.build(params[:report_join])
    @report_setup.add_join(@report_join)
    respond_with @report_join
  end

  # PUT /report_joins/1
  # PUT /report_joins/1.xml
  def update
    @report_join = @report_setup.joins.find(params[:id])
    
    @report_join.update_attributes(params[:report_join]) && @report_setup.update_join(@report_join)
    
    respond_with @report_join
  end

  # DELETE /report_joins/1
  # DELETE /report_joins/1.xml
  def destroy
    
    @report_join = @report_setup.joins.find(params[:id])
    @report_setup.remove_join(@report_join)

    respond_with @report_join
  end

  def report_joins_url
    "/report_joins"
  end

  def report_join_url(report_join)
    "/report_joins/#{report_join.id}"
  end
end
