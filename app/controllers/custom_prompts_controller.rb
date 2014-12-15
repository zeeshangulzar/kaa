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
      render :json => { :errors => ["Must pass custom_promptable id"] }, :status => :unprocessable_entity
    end
  end

  # Gets the list of custom_prompts for a user instance
  #
  # @url [GET] /promotions/1/custom_prompts
  # @authorize Master
  # @return [Array<CustomPrompt>] Array of all custom_prompts
  # @param [Integer] custom_promptable_id The id of the owner of the custom_prompts
  # @param [String] custom_promptable_type The type of the owner of the custom_prompt
  # [URL] /:custom_promptable_type/:custom_promptable_id/custom_prompts [GET]
  #  [200 OK] Successfully retrieved CustomPrompts Array object
  #   # Example response
  #    [{
  #     "id": 1,
  #     "custom_promptable_type": "Promotion,
  #     "custom_promptable_id": 1
  #     "sequence": 1,
  #     "prompt": 'How much exercise?'
  #     "short_label": 'Exercise',
  #     "data_type": 'integer'
  #     "type_of_prompt": 'dropdown',
  #     "options": ['15min', '30min', '45min', '60min'],
  #     "is_active": true,
  #     "is_required": true,
  #     "url": "http://api.hesapps.com/custom_prompts/1"
  #    }]
  def index
    @custom_prompts = @custom_promptable.custom_prompts
    respond_with @custom_prompts
  end

  # Gets a single custom_prompt for a user
  #
  # @url [GET] /custom_prompts/1
  # @authorize Master
  # @param [Integer] id The id of the custom_prompt
  # @return [CustomPrompt] CustomPrompt that matches the id
  #
  # [URL] /custom_prompts/:id [GET]
  #  [200 OK] Successfully retrieved CustomPrompt object
  #   # Example response
  #    {
  #     "id": 1,
  #     "custom_promptable_type": "Promotion,
  #     "custom_promptable_id": 1
  #     "sequence": 1,
  #     "prompt": 'How much exercise?'
  #     "short_label": 'Exercise',
  #     "data_type": 'integer'
  #     "type_of_prompt": 'dropdown',
  #     "options": ['15min', '30min', '45min', '60min'],
  #     "is_active": true,
  #     "is_required": true,
  #     "url": "http://api.hesapps.com/custom_prompts/1"
  #    }
  def show
    @custom_prompt = CustomPrompt.find(params[:id])
    respond_with @custom_prompt
  end

  # Creates a single custom_prompt for a user
  #
  # @url [POST] /promotions/1/custom_prompts
  # @authorize Master
  # @param [Integer] custom_promptable_id The id of the owner of the custom_prompts
  # @param [String] custom_promptable_type The type of the owner of the custom_prompts
  # @param [Integer] sequence The seqence that the custom prompt will appear in
  # @param [String] short_label The label of the custom prompt
  # @param [String] data_type The data type of the custom prompt. For example, "integer", "string"
  # @param [String] type_of_prompt The of prompt used to answer the custom prompt. For example, "text", "textfield", "dropdown", "checkbox", "likert".
  # @param [Array] options An array of options that can be used to answer custom prompt
  # @param [Boolean] is_active Whether or not the custom prompt is active
  # @param [Boolean] is_required Whether or not the custom prompt is required
  # @return [CustomPrompt] CustomPrompt that matches the id
  #
  # [URL] /:custom_promptable_type/:custom_promptable_id/custom_prompts [POST]
  #  [201 CREATED] Successfully created CustomPrompt object
  #   # Example response
  #    {
  #     "id": 1,
  #     "custom_promptable_type": "Promotion,
  #     "custom_promptable_id": 1
  #     "sequence": 1,
  #     "prompt": 'How much exercise?'
  #     "short_label": 'Exercise',
  #     "data_type": 'integer'
  #     "type_of_prompt": 'dropdown',
  #     "options": ['15min', '30min', '45min', '60min'],
  #     "is_active": true,
  #     "is_required": true,
  #     "url": "http://api.hesapps.com/custom_prompts/1"
  #    }
  def create
    @custom_prompt = @custom_promptable.custom_prompts.create(params[:custom_prompt])
    respond_with @custom_prompt
  end

  # Creates a single custom_prompt for a user
  #
  # @url [PUT] /custom_prompts/1
  # @authorize Master
  # @param [Integer] id The id of the custom_prompt
  # @param [Integer] sequence The seqence that the custom prompt will appear in
  # @param [String] short_label The label of the custom prompt
  # @param [String] data_type The data type of the custom prompt. For example, "integer", "string"
  # @param [String] type_of_prompt The of prompt used to answer the custom prompt. For example, "text", "textfield", "dropdown", "checkbox", "likert".
  # @param [Array] options An array of options that can be used to answer custom prompt
  # @param [Boolean] is_active Whether or not the custom prompt is active
  # @param [Boolean] is_required Whether or not the custom prompt is required
  # @return [CustomPrompt] CustomPrompt that matches the id
  #
  # [URL] /custom_prompts/:id [POST]
  #  [201 CREATED] Successfully created CustomPrompt object
  #   # Example response
  #    {
  #     "id": 1,
  #     "custom_promptable_type": "Promotion,
  #     "custom_promptable_id": 1
  #     "sequence": 1,
  #     "prompt": 'How much exercise?'
  #     "short_label": 'Exercise',
  #     "data_type": 'integer'
  #     "type_of_prompt": 'dropdown',
  #     "options": ['15min', '30min', '45min', '60min'],
  #     "is_active": true,
  #     "is_required": true,
  #     "url": "http://api.hesapps.com/custom_prompts/1"
  #    }
  def update
    @custom_prompt = CustomPrompt.find(params[:id])
    @custom_prompt.update_attributes(params[:custom_prompt])
    respond_with @custom_prompt
  end

  # Deletes a single custom_prompt from a user
  #
  # @url [DELETE] /custom_prompts/1
  # @authorize Master
  # @param [Integer] id The id of the custom_prompt
  # @return [CustomPrompt] CustomPrompt that was just deleted
  #
  # [URL] /custom_prompts/:id [DELETE]
  #  [200 OK] Successfully destroyed CustomPrompt object
  #   # Example response
  #    {
  #     "id": 1,
  #     "custom_promptable_type": "Promotion,
  #     "custom_promptable_id": 1
  #     "sequence": 1,
  #     "prompt": 'How much exercise?'
  #     "short_label": 'Exercise',
  #     "data_type": 'integer'
  #     "type_of_prompt": 'dropdown',
  #     "options": ['15min', '30min', '45min', '60min'],
  #     "is_active": true,
  #     "is_required": true,
  #     "url": "http://api.hesapps.com/custom_prompts/1"
  #    }
  def destroy
  	@custom_prompt = CustomPrompt.find(params[:id])
  	@custom_prompt.destroy
  	respond_with @custom_prompt
  end
end