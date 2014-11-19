# Include hook code here
require 'many_to_many'

ActiveRecord::Base.send(:include,ManyToMany)
