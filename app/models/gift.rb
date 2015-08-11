class Gift < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :name, :content, :summary, :image, :visible_date, :public
  attr_privacy :sequence, :master
  belongs_to :promotion

  has_many :entries_gifts
  
  # Name, type of prompt and sequence are all required
  validates_presence_of :name

  mount_uploader :image, GiftImageUploader

  def visible_date
    return self.promotion.starts_on + (self.sequence || 0)
  end
  
end
