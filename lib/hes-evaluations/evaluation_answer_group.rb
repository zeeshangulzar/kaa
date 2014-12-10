module HesEvaluations

  # Holds all the answers to the evaluation questions in groups
  class EvaluationAnswerGroup
    # Stores all answer groups in private class variable
    @@answer_groups = {}

    attr_reader :name

    # Finds an answer group by the name
    # @param [String] name of answer group
    # @return [EvaluationAnswerGroup] that matches the name
    def self.find(name)
      @@answer_groups[name]
    end

    # Deletes an answer group
    def destroy
      @@answer_groups.delete(name)
    end

    # Returns a list of answers that can be stored in an evaluation question answer
    # @return [Array<String, Integer>] list of answers
    def answers
      @answers.collect{|x| x.is_a?(Array) ? x.last : x}
    end

    # Return a list of labels that can be used to display as an answer for an evaluation question
    # @return [Array<String>] list of answer labels
    # @note Should not be used to save answer to question in database
    def labels
      @answers.collect{|x| x.is_a?(Array) ? x.first : x}
    end

    # Initializes an EvaluationAnswerGroup
    # @param [String, Symbol] name of the answer group
    # @param [Array<String, Integer, Array>] answers that can be used to answer a question, use nested array if answers need labels
    def initialize(name, answers)
      @name = name
      @answers = answers

      @@answer_groups[@name] = self
    end

    # Gets a random answer, used for testing
    def get_random_answer
      answer = @answers[rand(@answers.size)]
      answer.is_a?(Array) ? answer.last : answer
    end

    # Makes answer group serializable
    def serializable_hash(options = {})
      @answers
    end
  end
end
