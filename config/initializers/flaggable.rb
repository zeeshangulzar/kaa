# Include hook code here
require 'flaggable/flaggable'

ActiveRecord::Base.send(:include,Flaggable)
