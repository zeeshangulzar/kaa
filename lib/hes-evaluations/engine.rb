require "hes-authorization"
#require "hes-api"
# require "hes-flaggable"
require "hes-notifier"
require "hes-custom_prompts"
require "hes-sequencer"

# require File.dirname(__FILE__) + "/evaluation_definition_flags"
require File.dirname(__FILE__) + "/evaluation_question"
require File.dirname(__FILE__) + "/evaluation_answer_group"
require File.dirname(__FILE__) + "/has_evaluations"
require File.dirname(__FILE__) + "/evaluation_validator"

module HesEvaluations
	# Engine for initializing Evaluations
  class Engine < ::Rails::Engine

  	
    ActiveRecord::Base.send(:include, HasEvaluations)
    # EvaluationDefinition.send(:include , EvaluationDefinitionFlags) if ActiveRecord::Base.connection.tables.include?("evaluation_definitions") && ActiveRecord::Base.connection.tables.include?(HesFlaggable.flag_def_table_name)

    config.after_initialize do

      if ActiveRecord::Base.connection.tables.include?("custom_prompts")
        CustomPrompt.class_eval do
          def name
            self.short_label.downcase.gsub(' ', '_')
          end
        end
        
        # CustomPrompt.all.each do |custom_prompt|
        #   if custom_prompt.custom_promptable.respond_to?(:add_custom_prompt_to_evaluation_definitions)
        #     custom_prompt.custom_promptable.add_custom_prompt_to_evaluation_definitions(custom_prompt)
        #   end
        # end
      else
        puts "Could not find custom_prompts table. Please run 'rails generator hes:custom_prompts' and then 'rake db:migrate' to install."
      end
    end

  end
end
