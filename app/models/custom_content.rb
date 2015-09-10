# NOTE:
# default custom content has promotion_id = null/nil
class CustomContent < ApplicationModel
  self.table_name = "custom_content"
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :location_id, :category, :key, :title_html, :description_html, :summary_html, :content_html, :image, :caption_html, :sequence, :public
  attr_privacy :title, :description, :summary, :content, :caption, :master

  belongs_to :promotion
  has_many :custom_content_archives, :order => "archived_at DESC"

  MARKDOWN_COLUMNS = ['title_html','description_html','summary_html','content_html','caption_html']
  
  before_save :fix_promotion_id
  before_save :resync_markdown_columns
  after_save :archive

  validates_presence_of :category, :key

  mount_uploader :image, CustomContentImageUploader

  # override the markdown columns' methods to substitute promotion keywords
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

  def fix_promotion_id
    if !self.promotion_id.nil? && self.promotion.is_default?
      self.promotion_id = nil
    end
  end
  
  # say you have a column named summary and it has markdown.  for better performance, convert the summary to markdown on SAVE rather than ON RENDER
  # now you can return summary_markdown to the browser QUICKLY rather than Markdown.new(summary).to_html SLOWLY
  def resync_markdown_columns
    CustomContent::MARKDOWN_COLUMNS.each do |col|
      markdown_column_name = col
      original_column_name = markdown_column_name.to_s.gsub(/_html$/,'')
      value = self.send(original_column_name)
      fixed_underscores = !value.nil? ? value.gsub(/_/,'\_') : ''
      html = Markdown.new(fixed_underscores).to_html
      self.send("#{markdown_column_name}=",html)
    end
  end

  # gets content as customized for a promotion, default content is pulled in addition to promotion content, both custom and overriding defaults
  def self.for(promotion, conditions)
    conditions = {
      :category => nil,
      :key => nil
    }.merge(conditions)

    promotion_id = promotion.is_default? ? 'null' : promotion.id

    custom_content = self.find_by_sql("
      SELECT
        *
      FROM `custom_content`
      WHERE
        `promotion_id` = #{promotion_id}
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
            `promotion_id` = #{promotion_id}
        )
        #{"AND `category` = #{sanitize(conditions[:category])}" if !conditions[:category].nil?}
        #{"AND `key` = #{sanitize(conditions[:key])}" if !conditions[:key].nil?}
      ORDER BY `category` ASC, `sequence` ASC
    ")
    return custom_content
  end

  def archive
    CustomContentArchive::archive(self)
  end

  # nice method to copy content
  # can copy everything in promo, a specific category, or specific objects
  def self.copy(from, to, options = {})
    pf = Promotion.find(from) rescue nil
    pt = Promotion.find(to) rescue nil
    return false if !pf || !pt
    cc = pf.custom_content 
    if options[:category]
      cc = pf.custom_content.where(:category => category)
    end
    if options[:ids]
      cc = pf.custom_content.find(:all, :conditions => {:id => options[:ids]})
    end
    copied = []
    cc.each{|content|
      copied_content = content.dup
      copied_content.id = nil
      copied_content.promotion_id = pt.id
      copied_content.save!
      copied << copied_content
    }
    if copied.size == 1
      return copied.first
    end
    return copied
  end

  def promotion
    # return the default promotion if id is nil
    return self.promotion_id.nil? ? Promotion::get_default : Promotion.find(self.promotion_id)
  end

end
