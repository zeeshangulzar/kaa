class Behavior < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :name, :content, :summary, :image, :sequence, :public

  belongs_to :promotion

  has_many :entries_behaviors
  
  # Name, type of prompt and sequence are all required
  validates_presence_of :name, :summary

  mount_uploader :image, BehaviorImageUploader
  
end
