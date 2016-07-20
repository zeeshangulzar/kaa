class PromotionMap < ApplicationModel
  attr_privacy :id, :promotion_id, :map_id, :public
  attr_privacy_no_path_to_user
  attr_accessible *column_names
end