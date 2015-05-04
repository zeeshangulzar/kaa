class ReportFieldsController < ApplicationController
  respond_to :json
  wrap_parameters :report_field, :include => [:category, :sql_phrase, :sensitive, :sequence, :join, :filterable, :visible, :role, :display_name, :aggregate, :identification]
  before_filter :get_report_setup

  authorize :index, :coordinator
  
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
      fields = @report_setup.add_custom_prompts(fields, @promotion)
      fields = @report_setup.add_other_promotion_specific_fields(fields, @promotion)

      # @report_fields = @report_fields.values
      @report_fields = []
      fields.each do |id, field|
        field[:id] = id
        @report_fields << field
      end

    end

    respond_with @report_fields
  end

  # POST /report_fields
  # POST /report_fields.xml
  def create
    @report_field = @report_setup.report_fields.build(params[:report_field])
    @report_setup.add_field(@report_field)
    respond_with @report_field
  end

  # PUT /report_fields/1
  # PUT /report_fields/1.xml
  def update
    @report_field = @report_setup.report_fields.find(params[:id])
    
    @report_field.update_attributes(params[:report_field]) && @report_setup.update_field(@report_field)
    
    respond_with @report_field
  end

  # DELETE /report_fields/1
  # DELETE /report_fields/1.xml
  def destroy
    
    @report_field = @report_setup.report_fields.find(params[:id])
    @report_setup.remove_field(@report_field)

    respond_with @report_field
  end

  def report_fields_url
    "/report_fields"
  end

  def report_field_url(report_field)
    "/report_fields/#{report_field.id}"
  end
end
