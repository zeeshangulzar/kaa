class Organization < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :reseller_id, :name, :is_sso_enabled, :is_hes_info_removed, :sso_label, :sso_login_url, :sso_redirect, :public
  attr_privacy :contact_name, :contact_email, :wskey, :promotions_count, :master
  belongs_to :reseller
  has_many :promotions, :dependent => :destroy

  after_initialize :set_default_values, :if => 'new_record?'

  def set_default_values
    self.wskey ||= SecureRandom.hex(32)
  end

  def promotions_count
    self.promotions.size
  end
end
