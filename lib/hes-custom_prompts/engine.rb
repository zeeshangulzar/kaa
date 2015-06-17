require File.dirname(__FILE__) + "/has_custom_prompts"
require File.dirname(__FILE__) + "/custom_prompt_owner"
require File.dirname(__FILE__) + "/custom_prompt_owner"

module HesCustomPrompts
	# Custom Prompt engine to initialize
  class Engine < ::Rails::Engine

  	initializer "hes-custom_prompts" do |app|
  		ActiveRecord::Base.send(:include, HesCustomPrompts::HasCustomPrompts)
  	end

  end
end
