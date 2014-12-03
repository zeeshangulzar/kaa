require 'bcrypt'

class User < ApplicationModel

  # attrs
  attr_protected :role, :auth_key
  attr_privacy_no_path_to_user
  attr_privacy :email, :public
  attr_privacy :username, :me

  # validation
  validates_presence_of :email, :role, :promotion_id, :organization_id, :reseller_id, :username, :password
  validates_uniqueness_of :email, :scope => :promotion_id

  # relationships
  has_one :profile, :in_json => true
  belongs_to :promotion
  has_many :userTiles, :dependent => :destroy
  has_many :entries, :order => :recorded_on
  has_many :evaluations, :dependent => :destroy

  has_many :created_challenges, :foreign_key => 'created_by', :class_name => "Challenge"

  has_many :challenges_sent, :class_name => "ChallengeSent"
  has_many :challenges_received, :class_name => "ChallengeReceived"

  has_many :groups, :foreign_key => "owner_id"
  
  accepts_nested_attributes_for :profile, :evaluations, :created_challenges
  attr_accessor :include_evaluation_definitions
  
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

  # modules
  assigned_to_location

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
    user_json = super(options.merge(:include=>:profile))

    if self.include_evaluation_definitions || options[:include_evaluation_definitions]
      _evaluations_definitions = self.evaluations.collect{|x| x.definition.id}
      user_json["evaluation_definitions"] = _evaluations_definitions
    end

    user_json
  end

  def auth_basic_header
    b64 = Base64.encode64("#{self.id}:#{self.auth_key}").gsub("\n","")
    "Basic #{b64}"
  end

  def has_made_self_known_to_public?
    return true
  end

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  # Gets the next evaluation definition for a user
  # @return [EvaluationDefinition] evaluation definition that hasn't been completed
  def get_next_evaluation_definition
    return @next_eval_definition if @next_eval_definition

    eval_definations = self.evaluations.collect{|x| x.definition}
    @next_eval_definition = (promotion.evaluation_definitions - eval_definations).first

    @next_eval_definition
  end

end
