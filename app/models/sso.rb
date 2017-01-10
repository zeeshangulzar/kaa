class Sso < ApplicationModel
  self.table_name = 'ssos'
  belongs_to :promotion
  attr_accessible :promotion_id, :token, :session_token, :identifier, :first_name, :last_name, :email, :data, :used_at, :created_at, :updated_at

  after_initialize :set_session_token

  def set_session_token
    if new_record?
      self.session_token = SecureRandom.hex(25)
    end
  end

end
