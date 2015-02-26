class SuccessStory < ApplicationModel

  attr_privacy_path_to_user :user
  attr_privacy :user_id, :user, :title, :summary, :content, :image, :active, :featured, :promotion_id, :submitted1, :submitted2, :submitted3, :submitted4, :submitted_image, :any_user
  attr_accessible *column_names

  belongs_to :promotion
  belongs_to :user
  has_one :poster

  scope :active, :conditions => {:active => true}
  scope :featured, :conditions => {:featured => true}

  mount_uploader :image, SuccessStoryImageUploader
  mount_uploader :submitted_image, SuccessStorySubmittedImageUploader

  after_create :do_badges
  after_update :do_badges

  def do_badges
    Badge.do_all_star(self)
    Badge.do_time_to_shine(self)
  end



end
