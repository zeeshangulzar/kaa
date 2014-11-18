class Promotion < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :subdomain, :public

  belongs_to :organization
  has_many :users

  def current_date
    ActiveSupport::TimeZone[time_zone].today()
  end

  def current_time
    ActiveSupport::TimeZone[time_zone].now()
  end

end
