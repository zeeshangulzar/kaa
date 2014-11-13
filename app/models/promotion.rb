class Promotion < ActiveRecord::Base
  attr_accessible *column_names
  belongs_to :organization
  has_many :users
end
