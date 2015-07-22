class Reseller < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :name, :created_at, :updated_at, :contact_name, :contact_email, :master

  has_many :organizations
  has_many :promotions
end
