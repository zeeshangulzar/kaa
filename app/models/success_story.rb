class SuccessStory < ApplicationModel

  attr_privacy_path_to_user :user
  attr_privacy :user_id, :user, :title, :status, :summary, :content, :image, :featured, :promotion_id, :submitted1, :submitted2, :submitted3, :submitted4, :submitted_image, :any_user
  attr_accessible :user_id, :title, :summary, :content, :image, :status, :featured, :promotion_id, :submitted1, :submitted2, :submitted3, :submitted4, :submitted_image

  belongs_to :promotion
  belongs_to :user
  has_one :poster

  STATUS = {
    :unseen   => 0,
    :seen     => 1,
    :active   => 2,
    :rejected => 3
  }

  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end

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
