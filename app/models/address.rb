class Address < ActiveRecord::Base
  attr_accessible *column_names
  belongs_to :contact
end
