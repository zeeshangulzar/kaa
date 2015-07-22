class Organization < ApplicationModel
  attr_privacy_no_path_to_user
  attr_privacy :id, :reseller_id, :name, :wskey, :is_sso_enabled, :is_hes_info_removed, :sso_label, :sso_login_url, :sso_redirect, :password_min_length, :password_max_length, :password_min_numbers, :password_min_symbols, :password_max_attempts, :customized_path, :contact_name, :contact_email, :public
  belongs_to :reseller
  has_many :promotions, :dependent => :destroy
end
