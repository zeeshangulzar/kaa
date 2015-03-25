class Resource < ApplicationModel
  attr_privacy :content, :image, :summary, :promotion_id, :location_id, :public
  attr_privacy_no_path_to_user
  attr_accessible *column_names

  mount_uploader :image, ResourceImageUploader

  belongs_to :promotion
  belongs_to :location

end
