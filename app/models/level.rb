class Level < ApplicationModel
  belongs_to :promotion
  attr_privacy_no_path_to_user
  attr_accessible :name, :promotion_id, :min
  attr_privacy :name, :public

end