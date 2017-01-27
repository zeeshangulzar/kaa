class Reseller < ApplicationModel
  attr_accessible :name, :contact_name, :contact_email, :created_at, :updated_at
  attr_privacy_no_path_to_user
  attr_privacy :name, :created_at, :updated_at, :contact_name, :contact_email, :organizations_count, :promotions_count, :master

  has_many :organizations
  has_many :promotions, :through => :organizations

  def organizations_count 
    self.organizations.size
  end

  def promotions_count
    self.promotions.size
  end
end
