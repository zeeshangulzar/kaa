class Contact < ActiveRecord::Base
  attr_accessible *column_names
  attr_privacy_path_to_user :contactable
  attr_privacy :first_name,:last_name,:phone,:mobile_phone,:email,:contactable_id,:updated_at,:created_at,:me  
  attr_privacy :first_name,:last_name,:connections
  attr_privacy :first_name,:last_name,:public_comment

  belongs_to :contactable, :polymorphic => true
  has_one :address

  # Full name (if both first and last name are present)
  def full_name
    first_name.to_s + " " + last_name.to_s
  end

  # Email with full name returned or nil
  def email_with_name
    "#{full_name} <#{email.to_s}>"
  end
  
  def email_with_name_escaped
    email_with_name.gsub("<", "&lt;").gsub(">", "&gt;")
  end
end
