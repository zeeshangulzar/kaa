# NOTE:
# default custom content has promotion_id = null/nil
class CustomContent < ApplicationModel
  self.table_name = "custom_content"
  attr_accessible :promotion_id, :location_id, :category, :key, :title, :description, :summary, :content, :title_html, :description_html, :summary_html, :content_html, :image1, :caption, :caption_html, :sequence, :created_at, :updated_at, :group, :hidden, :image2
  attr_privacy_no_path_to_user
  attr_privacy :promotion_id, :location_id, :category, :key, :group, :title_html, :description_html, :summary_html, :content_html, :image1, :image2, :caption_html, :sequence, :public
  attr_privacy :title, :description, :summary, :content, :caption, :hidden, :master

  belongs_to :promotion
  has_many :custom_content_archives, :order => "archived_at DESC"

  MARKDOWN_COLUMNS = ['title_html','description_html','summary_html','content_html','caption_html']
  
  before_save :fix_promotion_id
  before_save :resync_markdown_columns
  after_save :archive

  validates_presence_of :category, :key

  mount_uploader :image1, CustomContentImage1Uploader
  mount_uploader :image2, CustomContentImage2Uploader

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
      :key      => nil,
      :group    => nil,
      :hidden   => false
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
        #{"AND `group` = #{sanitize(conditions[:group])}" if !conditions[:group].nil?}
        #{"AND (`hidden` = #{sanitize(conditions[:hidden])} OR `hidden` is NULL)" if !conditions[:hidden].nil?}
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
        #{"AND `group` = #{sanitize(conditions[:group])}" if !conditions[:group].nil?}
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

  # substitute promotion keywords for markdown columns
  def self.keyworded(custom_content, promotion = nil, user = nil)
    array_passed = custom_content.is_a?(Array)
    custom_contents = array_passed ? custom_content : [custom_content]
    promotion ||= self.promotion
    re = Regexp.union(promotion.keywords.keys)
    userRe = nil
    if !user.nil?
      userRe = Regexp.union(user.keywords.keys)
    end
    custom_contents.each{ |custom_content|
      MARKDOWN_COLUMNS.each{ |column|
        original = custom_content.send(column)
        with_keywords = original.gsub(re) { |m| promotion.keywords[m] }
        if !userRe.nil?
          with_keywords = with_keywords.gsub(userRe) { |m| user.keywords[m] }
        end
        custom_content.send("#{column}=", with_keywords)
      }
    }
    return array_passed ? custom_contents : custom_contents.first
  end

  # wrapper to grab a single custom content column for promotion keyworded and ready to go
  # TODO: this doesn't have fantastic error checking at the moment
  def self.get(column, conditions, promotion)
    cc = CustomContent.for(promotion, conditions)
    if !cc.empty?
      return CustomContent.keyworded(cc, promotion).first.send(column)
    end
    return nil
  end

end
