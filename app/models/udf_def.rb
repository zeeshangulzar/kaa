# Model that describes the user defined field definitions
class UdfDef < ApplicationModel

  validates_presence_of :owner_type, :parent_type, :parent_id, :data_type

  validates_format_of :owner_type, :with => /^[a-zA-Z0-9_]+$/, :message => "must be letters, numbers, and underscores only"
  validates_format_of :parent_type, :with => /^[a-zA-Z0-9_]+$/, :message => "must be letters, numbers, and underscores only"
  validates_format_of :parent_id, :with => /^[0-9]+$/, :message => "must be a positive integer"

  validates_with HesUdf::UdfDefValidator
  after_create :add_udf_column_to_owner_udfs_table

  # The parent that owns this user defined field
  # @return [ActiveRecord::Base] object that is tied to this udf
  def parent
    @parent ||= self.parent_type.constantize.find_by_id(self.parent_id) unless self.parent_type.nil? || self.parent_id.nil?
  end

  # The owner class that has the user defined field on it
  # @return [Class] class of the owner model
  def owner
    @owner ||= self.owner_type.constantize
  end

  # After udf def is created, add field to owner udf table
  def add_udf_column_to_owner_udfs_table
    other = self.data_type.to_sym == :string ? {:limit => 100} : self.data_type.to_sym == :decimal ? {:precision => 10, :scale => 2} : {}
    ActiveRecord::Migration.add_column self.ctn, self.cfn, self.data_type.to_sym, other rescue puts "#{self.cfn} column already created"
    conventialized_model.reset_column_information

    self.conventialized_model.send(:attr_accessible, self.cfn)
  end

  # After the udf def is deleted, drop the field on the owner udf table
  def remove_udf_column_to_owner_udfs_table
    ActiveRecord::Migration.remove_column self.ctn, self.cfn
    conventialized_model.reset_column_information
  end

  # The name of the field using the parent class and parent id
  # @return [String] name of the field that is associated to this user defined definition
  def conventionalized_field_name
    "#{self.parent_type.underscore}_#{self.parent_id}"
  end
  alias_method :cfn, :conventionalized_field_name

  # The name of the table where the user defined fields are stored at
  # @return [String] name of the owner table
  def conventionalized_table_name
    self.conventialized_model.table_name
  end
  alias_method :ctn, :conventionalized_table_name

  # The model that owns this UDF Definition
  # @return [Class] owner model
  def conventialized_model
    "#{self.owner_type}Udf".constantize
  end

  # Not sure what this function does, doesn't appear to be used but won't delete until positive
  # @return [Hash] hash with table name, field name, and data type
  def conventionalize
    return {
      :table_name => ctn,
      :field_name => cfn,
      :data_type => self.data_type.to_sym
    }
  end
end
