class EvaluationDefinitionsController < ApplicationController

  authorize :index, :show, :public
  authorize :create, :update, :destroy, :coordinator

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.evaluation_definitions : EvaluationDefinition
  end
  private :set_sandbox

  # Returns the list of parameters which will be selected for wrapped.
  # Override this method since multiple ruby instances cannot easily be notified
  # that a custom prompt has been added and more attributes are accessible
  def _wrap_parameters(parameters)
    value = nil

    _wrapper_options[:include] = []
    EvaluationDefinition.reset_column_information
    EvaluationDefinition.reset_flag_def

    EvaluationDefinition.flag_def.each do |fd|
      EvaluationDefinition.flag(fd.flag_name, :default => fd.default, :update_existing => false)
    end

    _wrapper_options[:include] = EvaluationDefinition.accessible_attributes(:default).to_a
    _wrapper_options[:include] = Array.wrap(_wrapper_options[:include]).collect(&:to_s) if _wrapper_options[:include]

    if include_only = _wrapper_options[:include]
      value = parameters.slice(*include_only)
    else
      exclude = _wrapper_options[:exclude] || []
      value = parameters.except(*(exclude + EXCLUDE_PARAMETERS))
    end

    { _wrapper_key => value }
  end


  def index
    evaluation_definitions = @SB.all
    return HESResponder(evaluation_definitions)
  end

  def show
    evaluation_definition = @SB.find(params[:id]) rescue nil
    return HESResponder("Evaluation definition", "NOT_FOUND") if !evaluation_definition
    return HESResponder(evaluation_definition)
  end

  def create
    evaluation_definition = @SB.create(params[:evaluation_definition])
    return HESResponder(evaluation_definition.errors.full_messages, "ERROR") if !evaluation_definition.valid?
    return HESResponder(evaluation_definition)
  end

  def update
    evaluation_definition = @SB.find(params[:id]) rescue nil
    return HESResponder("Evaluation definition", "NOT_FOUND") if !evaluation_definition
    EvaluationDefinition.transaction do
      evaluation_definition.update_attributes(params[:evaluation_definition])
    end
    return HESResponder(evaluation_definition)
  end

  def destroy
    evaluation_definition = @SB.find(params[:id]) rescue nil
    return HESResponder("Evaluation definition", "NOT_FOUND") if !evaluation_definition
    EvaluationDefinition.transaction do
      if evaluation_definition.destroy
        return HESResponder(evaluation_definition)
      else
        return HESResponder("Error deleting.", "ERROR")
      end
    end
  end
end
