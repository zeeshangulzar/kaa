class Tip < ContentModel
  column :day, :integer
  column :title, :string, :limit => 500
  column :summary, :text
  column :content, :text
  column :full_image_url, :string
  column :small_image_url, :string
  column :email_image_url, :string
  column :email_subject, :string
  column :email_image_caption, :text

  customize_by :promotion
  
  markdown :summary, :content
end
