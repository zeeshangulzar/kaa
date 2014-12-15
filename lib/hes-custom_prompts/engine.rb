require "hes-authorization"
#require "hes-api"
#require "hes-udf"
require "hes-events"

require File.dirname(__FILE__) + "/has_custom_prompts"
require File.dirname(__FILE__) + "/custom_prompt_owner"
require File.dirname(__FILE__) + "/custom_prompt_owner"

#require File.dirname(__FILE__) + "/generators/hes-custom_prompts_generator"

module HesCustomPrompts
	# Custom Prompt engine to initialize
  class Engine < ::Rails::Engine

#  	initializer "hes-custom_prompts" do |app|
  		ActiveRecord::Base.send(:include, HesCustomPrompts::HasCustomPrompts)
#  	end

#    config.generators do |g|
#      g.test_framework :rspec, :view_specs => false
#    end
  end
end
