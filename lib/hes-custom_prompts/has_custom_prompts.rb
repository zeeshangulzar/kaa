module HesCustomPrompts
	# Extends ActiveRecord so that custom prompts can be added
	module HasCustomPrompts
		# Extends model to include class method of initialize custom prompts
		# @param [ActiveRecord] base model to extend
		def self.included(base)
			base.send(:extend, HasCustomPromptsClassMethods)
		end

		# Class methods to initialize custom prompts
		module HasCustomPromptsClassMethods
			# Initializes custom prompts on a model
			# @param [Hash] options
			# @example
			#  class Promotion < ActiveRecord::Base
			#   has_custom_prompts :with => :evaluations
			#   has_custom_prompts :with => [:assessments, :tests]
			def has_custom_prompts(options = {})
				self.send(:has_many, :custom_prompts, :as => :custom_promptable, :order => '`custom_prompts`.`sequence`', :dependent => :destroy)
				self.send(:cattr_accessor, :udf_types)
				self.send("udf_types=", options[:with] ? options[:with].is_a?(Array) ? options[:with] : [options[:with]] : [])
				options[:with].to_s.singularize.camelcase.constantize.send(:include, CustomPromptOwner)
			end
		end
	end
end
