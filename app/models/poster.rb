class Poster < ApplicationModel
  attr_privacy_no_path_to_user
  attr_privacy :user_id, :user, :title, :summary, :content, :image1, :image2, :image3, :image4, :active, :featured, :promotion_id, :visible_date, :success_story_id, :any_user
  attr_accessible *column_names

  belongs_to :promotion
  belongs_to :success_story



end