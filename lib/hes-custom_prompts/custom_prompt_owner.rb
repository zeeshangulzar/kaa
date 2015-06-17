module HesCustomPrompts
  # Makes a model able to own custom prompts
  module CustomPromptOwner
    # Adds udfable when included on a model
    # @param [ActiveRecord] base model to extend
    def self.included(base)
      base.send(:udfable)
      base.send(:include, CustomPromptOwnerInstanceMethods)

      base.send(:alias_method_chain, :attributes, :custom_prompts)
      base.send(:attr_accessor, :custom_prompts_attributes)
      base.send(:after_save, :save_custom_prompt_field_values)
    end

    module CustomPromptOwnerInstanceMethods
      def assign_attributes(_attributes = {}, _options = {})
        self.custom_prompts_attributes ||= {}
        custom_prompts.each do |custom_prompt|
          self.custom_prompts_attributes[custom_prompt.name.to_s] = _attributes.delete(custom_prompt.name.to_s) || _attributes.delete(custom_prompt.name.to_sym) || self.custom_prompts_attributes[custom_prompt.name.to_s]
        end

        super(_attributes, _options)
      end
      
      def custom_prompts
        @custom_prompts ||= udf_defs.collect{|x| x.parent}
      end

      def attributes_with_custom_prompts
        _attributes = attributes_without_custom_prompts

        custom_prompts.each do |custom_prompt|
          _attributes[custom_prompt.short_label.underscore] = self.udfs && self.udfs.send("custom_prompt_#{custom_prompt.id}")
        end
        _attributes
      end

      def save_custom_prompt_field_values
        if self.custom_prompts_attributes

        	udf_attributes = {}
        	@custom_prompts_attributes.each_pair do |field, value|
        		udf_attributes[custom_prompts.detect{|x| x.name == field}.udf_def.cfn] = value
        	end

          user_defined_fields = udfs || build_udfs
          user_defined_fields.update_attributes!(udf_attributes)
        end
      end

      def get_custom_prompt_field(name)
      	@custom_prompts_attributes && @custom_prompts_attributes[name] || attributes[name]
      end

      def set_custom_prompt_field(name, value)
      	@custom_prompts_attributes ||= {}
        @custom_prompts_attributes[name] = value
      end
    end
  end
end
