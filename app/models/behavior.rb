class Behavior < ApplicationModel
  attr_accessible :promotion_id, :name, :content, :summary, :sequence, :created_at, :updated_at, :image
  attr_privacy_no_path_to_user
  attr_privacy :name, :content, :summary, :image, :sequence, :public

  belongs_to :promotion

  has_many :entries_behaviors
  has_many :point_thresholds, :as => :pointable, :order => "min ASC"
  
  # Name, type of prompt and sequence are all required
  validates_presence_of :name, :summary

  mount_uploader :image, BehaviorImageUploader
  
end
