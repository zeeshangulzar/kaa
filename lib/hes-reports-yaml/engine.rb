#require "hes-authorization"
#require "hes-api"
#require "hes-evaluations"
#require "hes-custom_prompts"
#require "hes-competitions"
#require "hes-locations"
#require "hes-stats"
#require "hes-eligibilities"

#require File.dirname(__FILE__) + "/generators/hes-reports-yaml_generator"
#require File.dirname(__FILE__) + "/generators/hes-reports-yaml-config_generator"

require File.dirname(__FILE__) + "/has_reports"
require File.dirname(__FILE__) + "/has_yaml_content/has_yaml_content"
require File.dirname(__FILE__) + "/has_yaml_content/yaml_content_base"
require File.dirname(__FILE__) + "/has_yaml_content/yaml_content_base_array"
require File.dirname(__FILE__) + "/select_typed_rows"

module HesReportsYaml

	# Engine to initialize HesReportsYaml
	class Engine < ::Rails::Engine

		#initializer "HesReportsYaml" do |app|
			ActiveRecord::Base.send(:include, HesReportsYaml::HasYamlContent)
			ActiveRecord::Base.send(:extend, HesReportsYaml::HasReports)
	#	end

#		config.generators do |g|
#			g.test_framework :rspec, :view_specs => false
#		end
	end

end
