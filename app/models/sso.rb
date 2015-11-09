class Sso < ApplicationModel
  self.table_name = 'ssos'
  belongs_to :promotion
  attr_accessible *column_names

  after_initialize :set_session_token

  def set_session_token
    if new_record?
      self.session_token = SecureRandom.hex(25)
    end
  end

end
