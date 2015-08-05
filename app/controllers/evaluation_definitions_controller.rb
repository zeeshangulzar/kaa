class EvaluationDefinitionsController < ApplicationController

  respond_to :json

  authorize :index, :show, :public
  authorize :create, :update, :destroy, :coordinator

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
    evaluation_definitions = @promotion.evaluation_definitions
    return HESResponder(evaluation_definitions)
  end

  def show
    evaluation_definition = EvaluationDefinition.find(params[:id]) rescue nil
    return HESResponder("Evaluation definition", "NOT_FOUND") if !evaluation_definition
    return HESResponder(evaluation_definition)
  end

  def create
    evaluation_definition = @promotion.evaluation_definitions.create(params[:evaluation_definition])
    return HESResponder(evaluation_definition.errors.full_messages, "ERROR") if !evaluation_definition.valid?
    return HESResponder(evaluation_definition)
  end

  def update
    evaluation_definition = EvaluationDefinition.find(params[:id]) rescue nil
    return HESResponder("Evaluation definition", "NOT_FOUND") if !evaluation_definition
    EvaluationDefinition.transaction do
      evaluation_definition.update_attributes(params[:evaluation_definition])
    end
    return HESResponder(evaluation_definition)
  end

  def destroy
    evaluation_definition = EvaluationDefinition.find(params[:id]) rescue nil
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
