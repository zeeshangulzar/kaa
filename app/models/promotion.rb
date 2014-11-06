class Promotion < ActiveRecord::Base
  attr_accessible *column_names
  belongs_to :organization
  has_many :users
  has_one :contact, :as => :contactable, :dependent => :destroy
end
