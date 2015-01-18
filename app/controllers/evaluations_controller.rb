# Controller for handling all evaluation requests
class EvaluationsController < ApplicationController

  respond_to :json

  # Get the user before each request
  before_filter :get_eval_definition, :only => [:index, :create]
  # Get the user before each request
  before_filter :ensure_for_parent_resource, :only => [:index, :create]

  authorize :index, :destroy, :master
  authorize :show, :create, :user

  # Sets the evaluation definition
  #
  # @param [Integer] id of the evaluation definition with the evaluations
  def get_eval_definition
    unless params[:evaluation_definition_id].nil?
      @evaluation_definition = EvaluationDefinition.find(params[:evaluation_definition_id])
    end
  end

  # Checks to make sure a parent resource has been found
  def ensure_for_parent_resource
    if @evaluation_definition.nil?
      return HESResponder("Must pass evaluation definition id", "ERROR")
    end
  end

  # Gets the list of evaluations for a user instance
  #
  # @url [GET] /evaluation_definitions/1/evaluations
  # @authorize Master
  # @param [Integer] evaluation_definition_id The id of the evaluation definition of the evaluation
  # @return [Array] Array of all evaluations
  #
  # [URL] /evaluation_definitions/:evaluation_definition_id/evaluations [GET]
  #  [200 OK] Successfully retrieved Evaluations Array object
  #   # Example response
  #   [{
  #     "id": 1,
  #     "evaluation_definition_id": 1,
  #     "minutes_of_exercise_per_day": "15-30 min" // All questions that are turned in Evaluation Definition will be included in response
  #   }]
  def index
    @evaluations = @evaluation_definition.evaluations
    return HESResponder(@evaluations)
  end

  # Gets a single evaluation
  #
  # @url [GET] /evaluations/1
  # @authorize User
  # @param [Integer] id The id of the evaluation
  # @return [Evaluation] Evaluation that matches the id
  #
  # [URL] /evaluations/:id [GET]
  #  [200 OK] Successfully retrieved Evaluation object
  #   # Example response
  #   {
  #     "id": 1,
  #     "evaluation_definition_id": 1,
  #     "minutes_of_exercise_per_day": "15-30 min" // All questions that are turned in Evaluation Definition will be included in response
  #   }
  def show
    @evaluation = Evaluation.find(params[:id])
    if !@evaluation
      return HESResponder("Evaluation doesn't exist.", "NOT_FOUND")
    end
    if @evaluation.user != @current_user && !@current_user.master?
      return HESResponder("Access denied to evaluation.", "DENIED")
    end
    return HESResponder(@evaluations)
  end

  # Creates a single evaluation for an eval_definitionable object
  #
  # @url [POST] /evaluation_definitions/1/evaluations
  # @authorize User
  # @param [Integer] evaluation_definition_id The id of the evaluation definition of the evaluation
  # @param [String] [question_name] The answer to an evaluation definition question. All questions that are turned on can be posted.
  # @return [Evaluation] Evaluation that matches the id
  #
  # [URL] /evaluation_definitions/:evaluation_definition_id/evaluations [POST]
  #  [201 CREATED] Successfully created Evaluation object
  #   # Example response
  #   {
  #     "id": 1,
  #     "evaluation_definition_id": 1,
  #     "minutes_of_exercise_per_day": "15-30 min" // All questions that are turned in Evaluation Definition will be included in response
  #   }
  def create
    @evaluation = @evaluation_definition.evaluations.create(params[:evaluation])
    if !@evaluation.valid?
      return HESResponder(@evalution.errors.full_messages, "ERROR")
    end
    return HESResponder(@evaluation)
  end


  # Deletes a single evaluation
  #
  # @url [DELETE] /evaluations/1
  # @authorize Master
  # @param [Integer] id The id of the evaluation
  # @return [evaluation] Evaluation that was just deleted
  #
  # [URL] /evaluations/:id [DELETE]
  #  [200 OK] Successfully destroyed Evaluation object
  #   # Example response
  #   {
  #     "id": 1,
  #     "evaluation_definition_id": 1,
  #     "minutes_of_exercise_per_day": "15-30 min" // All questions that are turned in Evaluation Definition will be included in response
  #   }
  def destroy
    @evaluation = Evaluation.find(params[:id])
    if !@evaluation
      return HESResponder("Evaluation not found.", "NOT_FOUND")
    elsif @evaluation.destroy
      return HESResponder(@evaluation)
    else
      return HESResponder("Error deleting.", "DENIED")
    end
  end
end
