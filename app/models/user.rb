class User < ActiveRecord::Base
  attr_protected :role, :auth_key, :password

  Role = {:user => "User", :master => "Master", :reseller => "Reseller", :coordinator => "Coordinator", :sub_promotion_coordinator => "Sub Promotion Coordinator", :location_coordinator => "Location Coordinator", :poster => "Poster"}

  after_initialize :set_default_values, :if => 'new_record?'

  belongs_to :promotion
  has_one :contact, :as => :contactable

  before_create :set_parents

  include HESUserMixins

  def set_default_values
    self.role ||= Role[:user]
    self.auth_key ||= SecureRandom.hex(40)
  end

  def set_parents
    if self.promotion && self.promotion.organization
      self.organization_id = self.promotion.organization_id
      self.reseller_id = self.promotion.organization.reseller_id
    end
  end

  def as_json(options={})
    super(options.merge(:include=>:contact))
  end

  def auth_basic_header
    b64 = Base64.encode64("#{self.id}:#{self.auth_key}").gsub("\n","")
    "Authorization: Basic #{b64}"
  end

  def has_made_self_known_to_public?
    return true
  end
end
