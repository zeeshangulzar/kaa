class Fact < ContentModel
  column :date, :date
  column :title, :string, :limit => 500
  column :content, :text
  column :image, :string

  customize_by :promotion

  default_scope :order => "date ASC"
  
  markdown :content

  mount_uploader :image, FactImageUploader

end
