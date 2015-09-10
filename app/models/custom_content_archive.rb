class CustomContentArchive < ApplicationModel
  self.table_name = "custom_content_archive"
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :custom_content_id, :location_id, :category, :key, :title_html, :description_html, :summary_html, :content_html, :image, :caption_html, :sequence, :title, :description, :summary, :content, :caption, :archived_at, :master

  belongs_to :promotion
  belongs_to :custom_content

  def self.archive(custom_content)
    cca = custom_content.custom_content_archives.build()
    custom_content.class.column_names.reject{|col|col=='id' || col=='image'}.each{ |col|
      cca.send("#{col}=", custom_content.send("#{col}"))
    }
    cca.archived_at = DateTime.now
    cca.save!
  end

end
