# Controller for handling all evaluation requests
class EvaluationsController < ApplicationController

  respond_to :json

  before_filter :set_sandbox
  
  # Get the user before each request
  before_filter :get_eval_definition, :only => [:index, :create]
  # Get the user before each request
  before_filter :ensure_for_parent_resource, :only => [:index, :create]

  authorize :index, :destroy, :master
  authorize :show, :create, :user

  def set_sandbox
    # NOTE: this sandbox is PURPOSELY for EvaluationDefinitions, the parent resource of Evaluations
    @SB = use_sandbox? ? @promotion.evaluation_definitions : EvaluationDefinition
  end
  private :set_sandbox
  

  def get_eval_definition
    unless params[:evaluation_definition_id].nil?
      @evaluation_definition = @SB.find(params[:evaluation_definition_id])
    end
  end

  # Checks to make sure a parent resource has been found
  def ensure_for_parent_resource
    if @evaluation_definition.nil?
      return HESResponder("Must pass evaluation definition id", "ERROR")
    end
  end

  def index
    evaluations = @evaluation_definition.evaluations
    return HESResponder(evaluations)
  end

  def show
    evaluation = Evaluation.find(params[:id])
    if !evaluation
      return HESResponder("Evaluation doesn't exist.", "NOT_FOUND")
    end
    if evaluation.user.id != @current_user.id && !@current_user.master?
      return HESResponder("Access denied to evaluation.", "DENIED")
    end
    return HESResponder(evaluation)
  end

  def create
    params[:evaluation][:user_id] = @current_user.id
    evaluation = @evaluation_definition.evaluations.create(params[:evaluation])
    custom_prompt_keys = params.keys.select{|k|k.to_s =~ /^custom_prompt_/}
    unless custom_prompt_keys.empty?
      udfs = EvaluationUdf.new(:evaluation_id=>evaluation.id)
      custom_prompt_keys.each do |k|
        cpid = k.gsub(/custom_prompt_/,'')
        cp = CustomPrompt.find(cpid) rescue nil
        next if !cp
        val = params[k]
        if cp.type_of_prompt == 'CHECKBOX' && cp.data_type == 'string'
          val = (params[k].to_i == 1) ? 'Y' : 'N'
        end
        udfs[k] = val
      end
      udfs.save
    end

    if !evaluation.valid?
      return HESResponder(evaluation.errors.full_messages, "ERROR")
    end
    return HESResponder(evaluation)
  end

  def destroy
    evaluation = Evaluation.find(params[:id])
    if !evaluation
      return HESResponder("Evaluation not found.", "NOT_FOUND")
    elsif evaluation.destroy
      return HESResponder(evaluation)
    else
      return HESResponder("Error deleting.", "DENIED")
    end
  end
end
