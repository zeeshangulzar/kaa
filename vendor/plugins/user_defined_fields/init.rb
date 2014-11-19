# Include hook code here
require 'user_defined_fields'
require 'UDF'
require 'UDF_def'

ActiveRecord::Base.send(:include,UserDefinedFields)
