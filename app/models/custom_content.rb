class CustomContent < ApplicationModel
  self.table_name = "custom_content"
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :location_id, :category, :key, :title_html, :description_html, :summary_html, :content_html, :image, :caption_html, :sequence, :public
  attr_privacy :title, :description, :summary, :content, :caption, :master

  belongs_to :promotion
  has_many :custom_content_archives, :order => "archived_at DESC"

  MARKDOWN_COLUMNS = ['title_html','description_html','summary_html','content_html','caption_html']
  
  before_save :resync_markdown_columns
  before_save :archive

  validates_presence_of :category, :key

  MARKDOWN_COLUMNS.each{ |column|
    self.send(:define_method, "#{column}", 
      Proc.new {nil
        original = read_attribute(column.to_sym)
        if self.promotion.nil?
          next original
        end
        re = Regexp.union(self.promotion.keywords.keys)
        s = original.gsub(re) { |m| self.promotion.keywords[m] }
        next s
      }
    )
  }

  def archive
    CustomContentArchive::archive(self)
  end

  # say you have a column named summary and it has markdown.  for better performance, convert the summary to markdown on SAVE rather than ON RENDER
  # now you can return summary_markdown to the browser QUICKLY rather than Markdown.new(summary).to_html SLOWLY
  def resync_markdown_columns
    CustomContent::MARKDOWN_COLUMNS.each do |col|
      markdown_column_name = col
      original_column_name = markdown_column_name.to_s.gsub(/_html$/,'')
      html = Markdown.new(self.send(original_column_name)).to_html
      self.send("#{markdown_column_name}=",html)
    end
  end

  def self.for(promotion, conditions)
    conditions = {
      :category => nil,
      :key => nil
    }.merge(conditions)
    custom_content = self.find_by_sql("
      SELECT
        *
      FROM `custom_content`
      WHERE
        `promotion_id` = #{promotion.id}
        #{"AND `category` = #{sanitize(conditions[:category])}" if !conditions[:category].nil?}
        #{"AND `key` = #{sanitize(conditions[:key])}" if !conditions[:key].nil?}
      UNION
      SELECT
        *
      FROM `custom_content`
      WHERE
        `promotion_id` IS NULL
        AND CONCAT(`category`,`key`) NOT IN (
          SELECT
            CONCAT(`category`,`key`)
          FROM `custom_content`
          WHERE 
            `promotion_id` = #{promotion.id}
        )
        #{"AND `category` = #{sanitize(conditions[:category])}" if !conditions[:category].nil?}
        #{"AND `key` = #{sanitize(conditions[:key])}" if !conditions[:key].nil?}
      ORDER BY `category` ASC, `sequence` ASC
    ")
    return custom_content
  end

end
