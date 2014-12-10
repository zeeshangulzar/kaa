module HesEvaluations
	# Sets all the flags whether or not to display questions for an evaluation definition
	module EvaluationDefinitionFlags
		# Set flags when this module is included
		def self.included(eval_def_model)
		# 	# EvaluationQuestion.all.each do |question|
		# 	# 	eval_def_model.send(:flag, :"is_#{question.name}_displayed", :default => true)
		# 	# end
		end
	end
end
