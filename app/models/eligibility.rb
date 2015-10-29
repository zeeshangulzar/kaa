class Eligibility < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :user_id, :identifier, :email, :first_name, :last_name, :public
  attr_accessible *column_names
  
  belongs_to :promotion
  belongs_to :user
  
  validates_presence_of :identifier
  validates_uniqueness_of :identifier, :scope => :promotion_id, :message => "must be unique"

  DEFAULT_FIELDS = ['identifier', 'first_name', 'last_name', 'email']

end
