module HesUdf
  # Validator to make sure parent and owner are set correctly on a UDF definition
  class UdfDefValidator < ActiveModel::Validator
    # Make sure parent and owner are set correctly
    # @param [UdfDef] udf_def to validate
    def validate(udf_def)

      # is owner a class constant?
      owner = ActiveSupport::Inflector.constantize(udf_def.owner_type) rescue nil
      
      # is parent a class constant?
      parent = ActiveSupport::Inflector.constantize(udf_def.parent_type) rescue nil

      # Both parent and owner are class constants
      if !owner.nil? && !parent.nil?
        parent_instance = parent.send(:find_by_id, udf_def.parent_id)

        # If Parent instance could not be found
        if parent_instance.nil?
        	udf_def.errors.add :parent, "Could not find #{udf_def.parent.to_s} with id '#{udf_def.parent_id}'"

        # If parent instance was found but it is not the correct class
        elsif !parent_instance.is_a?(parent)
          udf_def.errors.add :parent, "Found #{udf_def.parent.to_s} with id '#{udf_def.parent_id}', but it is not of type #{udf_def.parent.to_s}"
        end

      elsif owner.nil?
      	udf_def.errors.add :owner_type, "#{udf_def.owner_type} is not a valid class constant" 
      elsif parent.nil?
        udf_def.errors.add :parent, "#{udf_def.parent_type} is not a valid class constant"
      end
    end
  end
end
