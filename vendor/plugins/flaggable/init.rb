# Include hook code here
require 'flaggable'

ActiveRecord::Base.send(:include,Flaggable)
