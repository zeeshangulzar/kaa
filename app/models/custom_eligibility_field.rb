class CustomEligibilityField < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :name, :data_type, :sequence, :file_position, :is_deleted, :master

  ColDefs = {'string'=>[:string,{:limit=>100}],'integer'=>[]}
  DataTypes = ColDefs.keys

  belongs_to :promotion

  def eligibility_column_name
    f="#{self.data_type}_#{self.sequence}"
    unless Eligibility.column_names.include?(f)
      Eligibility.reset_column_information
    end
    f
  end

  validates_each :data_type do |custom_eligibility_field,attr,value|
    custom_eligibility_field.errors.add attr,"is not one of: #{DataTypes.join(',')}" unless DataTypes.include?(value)
  end  

  def destroy
    update_attributes :is_deleted=>true
  end

  def before_create
    max_id = CustomEligibilityField.maximum(:sequence,:conditions=>["promotion_id = ? and data_type = ?", self.promotion_id, self.data_type]) || 0
    self.sequence = max_id + 1
  end

  def after_create
    Eligibility.reset_column_information
    unless Eligibility.column_names.include?(eligibility_column_name)
      new_col_def = ColDefs[self.data_type].dup
      new_col_def.insert(0,eligibility_column_name)
      connection.add_column :eligibilities, *new_col_def
    end
  end
end
