class Reseller < ActiveRecord::Base
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :name, :created_at, :updated_at, :master

  has_many :organizations
  has_one :contact, :as => :contactable, :dependent => :destroy
end
