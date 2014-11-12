class Organization < ActiveRecord::Base
  attr_accessible *column_names
  belongs_to :reseller
  has_many :promotions, :dependent => :destroy
end
