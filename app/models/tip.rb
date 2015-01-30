class Tip < ContentModel
  column :day, :integer
  column :title, :string, :limit => 500
  column :summary, :text
  column :content, :text
  column :full_image, :string
  column :small_image, :string
  column :email_image, :string
  column :email_subject, :string
  column :email_image_caption, :text

  customize_by :promotion

  default_scope :order => "day ASC"
  
  markdown :summary, :content

  mount_uploader :full_image, TipFullImageUploader
  mount_uploader :small_image, TipSmallImageUploader
  mount_uploader :email_image, TipEmailImageUploader

end
