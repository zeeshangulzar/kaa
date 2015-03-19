module HesEvaluations
  # Module that adds the ability to add evaluations to an ActiveRecord model
  module HasEvaluations
    # Extend class methods when included
    # @param [ActiveRecord::Base] base model
    def self.included(base)
      base.send(:extend, HasEvaluationsClassMethods)
    end

    # Class methods that initialize Evaluations on an ActiveRecord model
    module HasEvaluationsClassMethods
      # Initializes associations needed for evaluations to work on an ActiveRecord model.
      # Adds instance methods to model also
      def has_evaluations
        self.send(:has_many, :evaluation_definitions, :dependent => :destroy, :order => :days_from_start)
        self.send(:has_many, :evaluations, :through => :evaluation_definitions)
        #self.send(:has_custom_prompts, :with => :evaluations)

        self.send(:include, HasEvaluationsInstanceMethods)
        #self.send(:after_custom_prompt_added, :add_custom_prompt_to_evaluation_definitions)
      end
    end

    # Instance methods used on an ActiveRecord model that has evaluations
    module HasEvaluationsInstanceMethods
      # Adds a flag for turning on and off a custom prompt question
      # @param [CustomPrompt] custom_prompt that was just created
      def add_custom_prompt_to_evaluation_definitions(custom_prompt)
        # EvaluationDefinition.send(:flag, "is_#{custom_prompt.name}_displayed".to_sym, :default => true)
        # EvaluationDefinition.reset_column_information
      end
    end
  end
end
