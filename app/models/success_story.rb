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

  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
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

  before_update :activate_featured
  after_update :unfeature_others

  def activate_featured
    # activate if featured
    if self.status != SuccessStory::STATUS[:active] && self.featured && !self.featured_was
      self.status = SuccessStory::STATUS[:active]
    end
  end

  def unfeature_others
    # only one success story can be featured at a time
    if self.status == SuccessStory::STATUS[:active] && self.featured && !self.featured_was
      sql = "UPDATE success_stories SET featured = 0 WHERE id != #{self.id}"
      connection.execute(sql)
    end
  end



end
