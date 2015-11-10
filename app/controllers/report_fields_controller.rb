class ReportFieldsController < ApplicationController
  respond_to :json
  wrap_parameters :report_field, :include => [:category, :sql_phrase, :sensitive, :sequence, :join, :filterable, :visible, :role, :display_name, :aggregate, :identification]
  before_filter :get_report_setup

  authorize :index, :location_coordinator
  
  def get_report_setup
    @promotion = Promotion.find(params[:promotion_id])
    @report_setup = @promotion.report_setup
  end
  private :get_report_setup
  
  # GET /report_fields
  # GET /report_fields.xml
  def index
    
    unless params[:promotionize]
      @report_fields = @report_setup.report_fields.sort{|x, y| x.display_name <=> y.display_name}
    else
      fields = @report_setup.fields

      fields = @report_setup.add_one_to_many_fields(fields, @promotion)
      fields = @report_setup.add_eval_questions(fields, @promotion)
      fields = @report_setup.add_other_promotion_specific_fields(fields, @promotion)
      # see lib/behaviors_for_reports.rb
      fields = BehaviorsForReports.add_behavior_fields(fields,@promotion)

      # @report_fields = @report_fields.values
      @report_fields = []
      fields.each do |id, field|
        if field[:visible]
          field[:id] = id
          @report_fields << field
        end
      end

    end

    return HESResponder({:data => @report_fields.as_json, :meta => nil})
  end

  # POST /report_fields
  # POST /report_fields.xml
  def create
    @report_field = @report_setup.report_fields.build(params[:report_field])
    @report_setup.add_field(@report_field)
    return HESResponder(@report_field)
  end

  # PUT /report_fields/1
  # PUT /report_fields/1.xml
  def update
    @report_field = @report_setup.report_fields.find(params[:id])
    
    @report_field.update_attributes(params[:report_field]) && @report_setup.update_field(@report_field)
    
    return HESResponder(@report_field)
  end

  # DELETE /report_fields/1
  # DELETE /report_fields/1.xml
  def destroy
    
    @report_field = @report_setup.report_fields.find(params[:id])
    @report_setup.remove_field(@report_field)

    return HESResponder(@report_field)
  end

  def report_fields_url
    return "/report_fields"
  end

  def report_field_url(report_field)
    return "/report_fields/#{report_field.id}"
  end
end
