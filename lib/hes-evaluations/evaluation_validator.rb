module HesEvaluations
	# Validator used to make sure questions are answered correctly in an evaluation
  class EvaluationValidator < ActiveModel::Validator
  	# Validates an evaluation to make user questions are answered correctly
    def validate(evaluation)
      EvaluationQuestion.all.each do |question|
        Rails.logger.info "Question: #{question.name}"
        Rails.logger.info "Question Answers: #{question.answers}"
        Rails.logger.info "Answer: #{evaluation.send(question.name)}"
        Rails.logger.info "Answer included: #{question.answers.include?(evaluation.send(question.name))}" if question.answers
        # if question.answers && !question.answers.include?(evaluation.send(question.name)) && evaluation.definition.send("is_#{question.name}_displayed?")
        #   evaluation.errors[question.name] << "#{question.name} must contain one of these answers: #{question.answers.join(", ")}"
        # end
      end
    end
  end
end
