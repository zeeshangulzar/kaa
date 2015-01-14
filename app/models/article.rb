class Article < ContentModel
  column :title, :string, :limit => 500
  column :summary, :text
  column :content, :text
  column :full_image_url, :string

  customize_by :promotion
end
