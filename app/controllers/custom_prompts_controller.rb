# Controller for handling all custom_prompt requests
class CustomPromptsController < ApplicationController
  respond_to :json

  # Get the user before each request
  before_filter :get_custom_promptable, :only => [:index, :create]

  authorize :all, :master

  # Get the user or render an error
  #
  # @param [Integer] custom_promptable_id of the owner of the custom_prompts
  # @param [String] custom_promptable_type of the owner of the custom_prompt
  def get_custom_promptable
    unless params[:custom_promptable_id].nil? || params[:custom_promptable_type].nil?
      @custom_promptable = params[:custom_promptable_type].singularize.camelcase.constantize.find(params[:custom_promptable_id])
    else
      return HESResponder("Must pass custom_promptable id", "ERROR")
    end
  end

  def index
    custom_prompts = @custom_promptable.custom_prompts
    return HESResponder(custom_prompts)
  end

  def show
    custom_prompt = CustomPrompt.find(params[:id]) rescue nil
    return HESResponder("Custom prompt", "NOT_FOUND") if !custom_prompt
    return HESResponder(custom_prompt)
  end

  def create
    custom_prompt = @custom_promptable.custom_prompts.build(params[:custom_prompt])
    return HESResponder(custom_prompt.errors.full_messages, "ERROR") if !custom_prompt.valid?
    CustomPrompt.transaction do
      custom_prompt.save!
      if params[:custom_prompt_evaluation] 
        add_prompt_to_evaluations(custom_prompt, params[:custom_prompt_evaluation])
      end
    end
    return HESResponder(custom_prompt)
  end

  def update
    custom_prompt = CustomPrompt.find(params[:id]) rescue nil
    return HESResponder("Custom prompt", "NOT_FOUND") if !custom_prompt
    CustomPrompt.transaction do
      custom_prompt.update_attributes(params[:custom_prompt])
      if params[:custom_prompt_evaluation] 
        add_prompt_to_evaluations(custom_prompt, params[:custom_prompt_evaluation])
      end
    end
    return HESResponder(custom_prompt.errors.full_messages, "ERROR") if !custom_prompt.valid?
    return HESResponder(custom_prompt)
  end

  def destroy
  	custom_prompt = CustomPrompt.find(params[:id])
  	custom_prompt.destroy
  	return HESResponder(custom_prompt)
  end


  def add_prompt_to_evaluations(custom_prompt, custom_prompt_evaluation)
    if(custom_prompt.custom_promptable_type == "Promotion")
      cp_promotion = Promotion.find(custom_prompt.custom_promptable_id)
      cp_promotion.evaluation_definitions.each do |ed|
        evaluationId = ed.id
        Rails.logger.warn  "CUSTOM PROMPT SYMBOL #{custom_prompt_evaluation["evaluation_#{evaluationId}".to_sym]}"
        if custom_prompt_evaluation["evaluation_#{evaluationId}".to_sym] == 1 || custom_prompt_evaluation["evaluation_#{evaluationId}".to_sym] == true
          ed.add_visible_question("custom_prompt_#{custom_prompt.id}")
        else 
          ed.remove_visible_question("custom_prompt_#{custom_prompt.id}")
        end
        ed.save!
      end
    end
  end
end
