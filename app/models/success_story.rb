class SuccessStory < ApplicationModel

  attr_privacy_path_to_user :user
  attr_privacy :user_id, :user, :title, :summary, :content, :image, :active, :featured, :promotion_id, :any_user

  belongs_to :promotion
  belongs_to :user
  has_one :poster

  scope :active, :conditions => {:active => true}
  scope :featured, :conditions => {:featured => true}
  

end