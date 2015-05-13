class Photo < ApplicationModel
  belongs_to :photoable, :polymorphic => true 
  belongs_to :user, :foreign_key => "user_id"
  
  attr_accessible *column_names
  attr_privacy :name, :caption, :description, :image, :flagged, :flagged_by, :user_id, :photoable_type, :photoable_id, :any_user
  attr_privacy_path_to_user :user

  mount_uploader :image, PhotoImageUploader

  scope :not_flagged, where(:flagged => false)
  scope :flagged, where(:flagged => true)

end