require 'bcrypt'

class User < ApplicationModel
  # attrs
  attr_protected :role, :auth_key
  attr_privacy :email, :public

  # validation
  validates_presence_of :email, :role, :promotion_id, :organization_id, :reseller_id, :username, :password
  validates_uniqueness_of :email, :scope => :promotion_id

  # relationships
  has_one :profile
  accepts_nested_attributes_for :profile
  
  belongs_to :promotion
  
  has_many :userTiles, :dependent => :destroy

  # hooks
  after_initialize :set_default_values, :if => 'new_record?'
  before_validation :set_parents, :on => :create

  # constants
  Role = {
    :user                       => "User",
    :master                     => "Master",
    :reseller                   => "Reseller",
    :coordinator                => "Coordinator",
    :sub_promotion_coordinator  => "Sub Promotion Coordinator",
    :location_coordinator       => "Location Coordinator",
    :poster                     => "Poster"
  }

  # includes
  include HESUserMixins
  include BCrypt

  # methods
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
    super(options.merge(:include=>:profile))
  end

  def auth_basic_header
    b64 = Base64.encode64("#{self.id}:#{self.auth_key}").gsub("\n","")
    "Basic #{b64}"
  end

  def has_made_self_known_to_public?
    return true
  end

  def password=(new_password)
    write_attribute(:password, Password.create(new_password))
  end

end
