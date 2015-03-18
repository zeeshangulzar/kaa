# Controller for handling all evaluation_definition requests
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


  # Gets the list of evaluation_definitions for a user instance
  #
  # @url [GET] /promotions/1/evaluation_definitions
  # @authorize Public
  # @param [Integer] promotion_id The id of the evaluation definition owner
  # @return [Array] of all evaluation_definitions
  #
  # [URL] /promotion/:promotion_id/evaluation_definitions
  #  [200 OK] Successfully retrieved EvaluationDefinition Array object
  #   # Example response
  #   [{
  #     "id": 1,
  #     "name": "Chicken Soup"
  #     "days_from_start": 56,
  #     "promotion_id": 1,
  #     "message": "Congrats! Take this evaluation now!",
  #     "sequence": 1,
  #     "questions": [{ // Example of only one question, there should be many more
  #       "name": 'exercise',
  #       "short_label": 'Exercise',
  #       "prompt": 'How much exercise per day?',
  #       "type_of_prompt": 'DROPDOWN',
  #       "data_type": 'string',
  #       "options": [
  #         "15 min", "30 min", "45 min", "60 min"
  #       ]
  #     }],
  #     "is_exericise_displayed": true, // Each question will have its own flag to toggle on and off
  #     "created_at": "2014-03-19T15:27:48-04:00",
  #     "updated_at": "2014-03-19T15:27:48-04:00",
  #     "url": "http://api.hesapps.com/evaluation_definitions/1"
  #   }]
  #
  # @note Response will also contain
  def index
    @evaluation_definitions = @promotion.evaluation_definitions.as_json
    return HESResponder(@evaluation_definitions)
  end

  # Gets a single evaluation_definition
  #
  # @url [GET] /evaluation_definitions/1
  # @authorize Public
  # @param [Integer] id the id of the evaluation definition
  # @return [EvaluationDefinition] EvaluationDefinition that matches the id
  #
  # [URL] /evaluation_definitions/:id [GET]
  #  [200 OK] Successfully retrieved EvaluationDefinition object
  #   # Example response
  #   {
  #     "id": 1,
  #     "name": "Chicken Soup"
  #     "days_from_start": 56,
  #     "promotion_id": 1,
  #     "message": "Congrats! Take this evaluation now!",
  #     "sequence": 1,
  #     "questions": [{ // Example of only one question, there should be many more
  #       "name": 'exercise',
  #       "short_label": 'Exercise',
  #       "prompt": 'How much exercise per day?',
  #       "type_of_prompt": 'DROPDOWN',
  #       "data_type": 'string',
  #       "options": [
  #         "15 min", "30 min", "45 min", "60 min"
  #       ]
  #     }],
  #     "is_exericise_displayed": true, // Each question will have its own flag to toggle on and off
  #     "created_at": "2014-03-19T15:27:48-04:00",
  #     "updated_at": "2014-03-19T15:27:48-04:00",
  #     "url": "http://api.hesapps.com/evaluation_definitions/1"
  #   }
  def show
    @evaluation_definition = EvaluationDefinition.find(params[:id])
    if !@evaluation_definition
      return HESResponder("Evaluation definition doesn't exist.", "NOT_FOUND")
    end
    return HESResponder(@evaluation_definition)
  end

  # Creates a single evaluation_definition for a promotion
  #
  # @url [POST] /promotions/1/evaluation_definitions
  # @authorize Master
  # @param [Integer] promotion_id The id of the evaluation definition owner
  # @param [Integer] id The id of the evaluation definition
  # @param [String] name The name of the evaluation definition
  # @param [Integer] days_from_start The number of days from the start of an evaluation definition owner to trigger evaluation
  # @param [String] message The message to present user when taking an evaluation
  # @param [Boolean] is_[question name]_displayed The flag that turns questions on and off
  # @return [EvaluationDefinition] EvaluationDefinition that matches the id
  #
  # [URL] /promotions/:promotion_id/evaluation_definitions [POST]
  #  [201 CREATED] Successfully created EvaluationDefinition object
  #   # Example response
  #   {
  #     "id": 1,
  #     "name": "Chicken Soup"
  #     "days_from_start": 56,
  #     "promotion_id": 1,
  #     "message": "Congrats! Take this evaluation now!",
  #     "sequence": 1,
  #     "questions": [{ // Example of only one question, there should be many more
  #       "name": 'exercise',
  #       "short_label": 'Exercise',
  #       "prompt": 'How much exercise per day?',
  #       "type_of_prompt": 'DROPDOWN',
  #       "data_type": 'string',
  #       "options": [
  #         "15 min", "30 min", "45 min", "60 min"
  #       ]
  #     }],
  #     "is_exericise_displayed": true, // Each question will have its own flag to toggle on and off
  #     "created_at": "2014-03-19T15:27:48-04:00",
  #     "updated_at": "2014-03-19T15:27:48-04:00",
  #     "url": "http://api.hesapps.com/evaluation_definitions/1"
  #   }
  def create
    @evaluation_definition = @promotion.evaluation_definitions.create(params[:evaluation_definition])
    if !@evaluation_definition.valid?
      return HESResponder(@evaluation_definition.errors.full_messages, "ERROR")
    end
    return HESResponder(@evaluation_definition)
  end

  # Updates a single evaluation_definition
  #
  # @url [PUT] /evaluation_definitions/1
  # @authorize Master
  # @param [Integer] id The id of the evaluation definition
  # @param [String] name The name of the evaluation definition
  # @param [Integer] days_from_start The number of days from the start of an evaluation definition owner to trigger evaluation
  # @param [String] message The message to present user when taking an evaluation
  # @param [Boolean] is_[question name]_displayed The flag that turns questions on and off
  # @return [EvaluationDefinition] that matches the id
  #
  # [URL] /evaluation_definitions/:id [GET]
  #  [200 OK] Successfully retrieved EvaluationDefinition object
  #   # Example response
  #   {
  #     "id": 1,
  #     "name": "Chicken Soup"
  #     "days_from_start": 56,
  #     "promotion_id": 1,
  #     "message": "Congrats! Take this evaluation now!",
  #     "sequence": 1,
  #     "questions": [{ // Example of only one question, there should be many more
  #       "name": 'exercise',
  #       "short_label": 'Exercise',
  #       "prompt": 'How much exercise per day?',
  #       "type_of_prompt": 'DROPDOWN',
  #       "data_type": 'string',
  #       "options": [
  #         "15 min", "30 min", "45 min", "60 min"
  #       ]
  #     }],
  #     "is_exericise_displayed": true, // Each question will have its own flag to toggle on and off
  #     "created_at": "2014-03-19T15:27:48-04:00",
  #     "updated_at": "2014-03-19T15:27:48-04:00",
  #     "url": "http://api.hesapps.com/evaluation_definitions/1"
  #   }
  def update
    @evaluation_definition = EvaluationDefinition.find(params[:id])
    @evaluation_definition.update_attributes(params[:evaluation_definition])
    return HESResponder(@evaluation_definition)
  end

  # Deletes a single evaluation_definition
  #
  # @url [DELETE] /evaluation_definitions/1
  # @authorize Master
  # @param [Integer] id The id of the evaluation definition
  # @return [EvaluationDefinition] EvaluationDefinition that was just deleted
  #
  # [URL] /evaluation_definitions/:id [DELETE]
  #  [200 OK] Successfully destroyed EvaluationDefinition object
  #   # Example response
  #   {
  #     "id": 1,
  #     "name": "Chicken Soup"
  #     "days_from_start": 56,
  #     "promotion_id": 1,
  #     "message": "Congrats! Take this evaluation now!",
  #     "sequence": 1,
  #     "questions": [{ // Example of only one question, there should be many more
  #       "name": 'exercise',
  #       "short_label": 'Exercise',
  #       "prompt": 'How much exercise per day?',
  #       "type_of_prompt": 'DROPDOWN',
  #       "data_type": 'string',
  #       "options": [
  #         "15 min", "30 min", "45 min", "60 min"
  #       ]
  #     }],
  #     "is_exericise_displayed": true, // Each question will have its own flag to toggle on and off
  #     "created_at": "2014-03-19T15:27:48-04:00",
  #     "updated_at": "2014-03-19T15:27:48-04:00",
  #     "url": "http://api.hesapps.com/evaluation_definitions/1"
  #   }
  def destroy
    @evaluation_definition = EvaluationDefinition.find(params[:id])
    if @evaluation_definition
      return HESResponder("Evaluation definition doesn't exist.", "NOT_FOUND")
    elsif @evaluation_definition.destroy
      return HESResponder(@evaluation_definition)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end
end
