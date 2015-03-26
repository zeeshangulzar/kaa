class Banner < ApplicationModel
  attr_privacy :image, :link_url, :name, :description, :promotion_id, :location_id, :public
  attr_privacy_no_path_to_user
  attr_accessible *column_names

  mount_uploader :image, BannerImageUploader

  belongs_to :promotion
  belongs_to :location

end