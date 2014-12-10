# Include hook code here
require 'user_defined_fields/user_defined_fields'

ActiveRecord::Base.send(:include,UserDefinedFields)
