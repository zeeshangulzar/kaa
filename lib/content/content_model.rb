class ContentModel < ActiveRecord::Base
  self.abstract_class = true
  self.before_save :resync_markdown_columns

  # self.after_save :clear_hes_cache
  # self.after_destroy :clear_hes_cache

  def self.initialize_content_model(options={})
    @@config ||= {}
    @@config[self] ||= {:defined_columns=>[],:cached_columns=>[],:markdown_columns=>[],:table_name=>self.name.underscore.pluralize, :routed=>false}

    unless connection.tables.include?(@@config[self][:table_name])
      connection.create_table @@config[self][:table_name]
    end
    
    if options[:clear_cached_column_names] || !@@config[self][:cached_column_names]
      self.table_name = @@config[self][:table_name]
      self.reset_column_information
      @@config[self][:cached_column_names] = self.columns.collect(&:name)
    end

    unless @@config[self][:routed]
      resource_name = self.name.pluralize.underscore.to_sym
      puts "ROUTED #{resource_name}"
      # this is a fancy hack for appending routes without blowing away current ones.
      # if routing continues to screw up, scrutinize this better...
      begin
        _routes = Rails.application.routes
        _routes.disable_clear_and_finalize = true
        _routes.clear!
        Rails.application.routes_reloader.paths.each{ |path| load(path) }
        _routes.draw do
          resources resource_name
        end
        ActiveSupport.on_load(:action_controller) { _routes.finalize! }
      ensure
        _routes.disable_clear_and_finalize = false
      end
      # end routing hack
      @@config[self][:routed] = true
    end
  end

  # note:  if you change args, you will have to alter the table yourself
  # i.e. if you start off with varchar and change it to int, this class will not alter the table to change the data type
  def self.column(column_name,*args)
    self.initialize_content_model
    @@config[self][:defined_columns] << {:column_name=>column_name.to_sym,:column_definition=>args}

    self.attr_accessible column_name.to_sym
    self.attr_privacy column_name.to_sym, :public
    self.attr_privacy_no_path_to_user

    unless @@config[self][:cached_column_names].include?(column_name.to_s)
      connection.add_column(@@config[self][:table_name], column_name, *args) rescue nil
      self.initialize_content_model(:clear_cached_column_names=>true)
    end
  end
  
  # if you have a column that stores markdown, then it can be converted to html for you
  # example: you have a column named summary that contains markdown
  #          ContentModel will define summary_html which stores the already-converted markdown as HTML
  #          this is a significant performance increase!
  def self.markdown(*column_names)
    self.initialize_content_model
    column_names.each do |column_name|
      markdown_column_name = "#{column_name}_html"
      column markdown_column_name, :text
      @@config[self][:markdown_columns] << {:column_name=>markdown_column_name.to_sym,:column_definition=>:text}
    end
  end

  # this method is used by ContentController to lighten the JSON payload -- 99.9% of web requests will NOT need markdown, just HTML, so exclude it
  def self.column_names_minus_markdown
    cols = [:id]
    markdown_columns = @@config[self][:markdown_columns].collect{|hash|hash[:column_name].to_sym}
    @@config[self][:defined_columns].each do |column_definition|
      html_column_name = "#{column_definition[:column_name]}_html".to_sym
      if markdown_columns.include?(html_column_name)
        # arrgh.  you have to include an empty string, or else ActiveModel::MissingAttributeError
        cols << "'' #{column_definition[:column_name]}"
      else
        cols << column_definition[:column_name]
      end
    end
    cols
  end

  # usually you have a model called Tip and table called tips
  # say you have a promotion with id 1234
  #   its set of custom tips COULD be in a model called Promotion1234Tip and in the table promotion_1234_tips
  #   ONLY if promotion 1234 has customized tips
  # SO this method will return EITHER the Promotion1234Tip class constant OR the Tip class constant
  # why is this important?
  #   - your controller code can simply do Tip.for_promtion(@promotion).find(:all) or Tip.for_promtion(@promotion).find(params[:id])
  #      - your controller code does not have to worry about whether Tip is customized for the Promotion
  def self.customize_by(parent)
    @@config[self][:customize_by] = parent

    make_custom_constants

    metaclass.instance_eval do
      define_method "for_#{parent}".to_sym do |instance_of_parent|
        return nil unless instance_of_parent
        customized_klass = "#{instance_of_parent.class.name}#{instance_of_parent.id}#{self.name}"
        if Object.const_defined?(customized_klass)
          return customized_klass.constantize
        else
          possible_table_name = customized_klass.underscore.pluralize
          if connection.tables.include?(possible_table_name)
            make_custom_constant_for_table_name(possible_table_name)
          else
            self
          end
        end
      end
    end
  end

  def self.to_s
    self.initialize_content_model
    return @@config.keys.first.name # I think the stuff below was for debugging/info purposes but other modules depend on Class::to_s returning the actual class name - BM 2015-09-02
    output = "=======================================================================================================\n"
    @@config.keys.each do |klass|
      output << "#{klass.name}\n"
      @@config[klass][:defined_columns].each do |column_definition_hash|
        output << "  #{column_definition_hash[:column_name]} #{column_definition_hash[:column_definition].inspect}\n"
      end
      output << "\n"
    end
    output << "=======================================================================================================\n"
    output
  end

  :private

  # say you know the Tip model can be customized by Promotion 
  # this is how you make the PromotionXXXTip classes -- by grepping the tables
  def self.make_custom_constants
    if @@config[self][:customize_by]
      get_custom_table_names.each do |table_name|
        table_name_klass = table_name.classify
        puts "defining #{table_name_klass}"
        define_custom_constant(table_name.klass)
      end
    end
  end

  # say you encountered a table named promotion_333_tips
  # this is how you make the Promotion333Tip class from that table name
  def self.make_custom_constant_for_table_name(table_name)
    custom_klass = table_name.classify
    define_custom_constant(custom_klass)
  end

  # this is what actually creates PromotionXXXTip class
  # it's potentially dangerous because it defines a constant.... 
  # but it's not likely to cause an accidental collision because it does not override previously-defined constants
  def self.define_custom_constant(custom_constant_name)
    unless Object.const_defined?(custom_constant_name)
      klass_new = Class.new(self)
      klass = Object.const_set(custom_constant_name,klass_new)
      klass.table_name = custom_constant_name.underscore.pluralize
      klass
    else
      custom_constant_name.constantize
    end
  end

  # this looks for tables matching a pattern such as promotion1234_tips
  def self.get_custom_table_names(parent_klass=@@config[self][:customize_by].to_s.underscore,customized_klass=self.name.underscore.pluralize)
    rows = connection.select_all "show tables like '#{parent_klass}%#{customized_klass}'"
    rows.collect{|hash|hash.values.first}
  end

  # say you have a column named summary and it has markdown.  for better performance, convert the summary to markdown on SAVE rather than ON RENDER
  # now you can return summary_markdown to the browser QUICKLY rather than Markdown.new(summary).to_html SLOWLY
  def resync_markdown_columns
    @@config[self.class][:markdown_columns].each do |hash|
      markdown_column_name = hash[:column_name]
      original_column_name = markdown_column_name.to_s.gsub(/_html$/,'')

      html = Markdown.new(self.send(original_column_name)).to_html
      self.send("#{markdown_column_name}=",html)
    end
  end

  def clear_hes_cache
    ApplicationController.hes_cache_clear self.class.name.underscore.pluralize
  end
end
