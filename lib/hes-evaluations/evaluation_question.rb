module HesEvaluations
  # Stores all the EvaluationQuestions that are asked in an application
  # @note Dynamic questions should be added using custom prompts
  class EvaluationQuestion
    # Stores all questions in private class variable
    @@questions = {}

    attr_accessor :name, :prompt, :column_options, :sequence, :default
    attr_reader :column_type

    # Finds a question by the name
    # @param [String, Symbol] name of the question
    # @return [EvaluationQuestion] that matches the name
    def self.find(name)
      @@questions[name.to_sym]
    end

    # Returns all questions that have been defined in this application
    # @return [Array<EvaluationQuestion>] all questions
    def self.all
      @@questions.values.sort{|x,y| x.sequence <=> y.sequence}
    end

    # Initializes an EvaluationQuestion
    # @param [String, Symbol] name of the question
    # @param [String] prompt or question text
    # @param [Array<String, Integer, Array>] answer_group of answers that can answer this question
    # @param [Hash] column_options in case default column settings are not enough
    # @example
    #  EvaluationQuestion.new(:screen_size, "What size is your screen?")
    # @example
    #  EvaluationQuestion.new(:screen_size, "What size is your screen", ["14 inches", "15 inches", "16 inches"])
    # @example
    #  EvaluationQuestion.new(:screen_size, "What size is your screen", ["14 inches", "15 inches", "16 inches"], :limit => 25)
    def initialize(name, prompt, answer_group = nil, default = false, column_options = {})
      @name = name
      @prompt = prompt
      @default = default
      
      @answer_group = answer_group
      if @answer_group && @answer_group.is_a?(Array)
        EvaluationAnswerGroup.new(@name, @answer_group )
        @answer_group = @name
      end


      @column_options = column_options || {}
      @column_type = nil
      @sequence = @@questions.keys.size + 1
      determine_column_options

      @@questions[@name.to_sym] = self
    end

    # Destroys an EvaluationQuestion
    def destroy
      @@questions.delete(name.to_sym)
      @@questions.keys.each_with_index do |key, index|
        @@questions[key].sequence = index + 1
      end
    end

    # The answers that can be used to answer the evaluation question
    # @return [Array<String>] answers that answer the question
    def answers
      @answer_group && EvaluationAnswerGroup.find(@answer_group).answers
    end

    # The labels of the answers that should be used to display the answers
    # @return [Array<String>] answer labels
    def answers_labels
      @answer_group && EvaluationAnswerGroup.find(@answer_group).labels
    end

    # Determines what type of column should be created in the database for an evaluation question
    def determine_column_options
      limit = nil

      # The answer will be a text field/area
      if @answer_group.nil?
        @column_type = :text
        limit = 250

        # The answer will be a digit
      elsif answers.first.is_a?(Integer)
        @column_type = :integer

        # The answer will be a string answer presented in a dropdown or radio button
      else
        @column_type = :string

        # Determine max length of answer
        limit = 0
        answers.each do |answer|
          limit = answer.size if answer.size > limit
        end
      end

      @column_options = {:limit => limit}.merge(@column_options) unless limit.nil? || limit.zero?
      @column_type = @column_options.delete(:type) || @column_type
    end

    # Inspects an EvaluationQuestion
    # @return [String] string format EvaluationQuestion object
    def inspect
      "#<#{self.class} @name => \"#{name}\", @prompt => \"#{@prompt}\", @answers => #{answers || "\"N/A\""} >"
    end

    # Hash of EvaluationQuestion, includes answer options
    # @return [Hash] form of EvaluationQuestion object
    def serializable_hash(options = {})
      _hash = {"short_label" => @name.to_s.humanize.titleize, "name" => @name.to_s, "prompt" => @prompt, "is_active" => true, "is_required" => true, "data_type" => @column_type.to_s, "type_of_prompt" => @answer_group.nil? ? "TEXTBOX" : "DROPDOWN"}
      _hash["options"] = EvaluationAnswerGroup.find(@answer_group).serializable_hash if @answer_group
      _hash
    end
  end
end
