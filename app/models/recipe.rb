class Recipe < ActiveRecord::Base
  attr_accessor :require_validation
  
  attr_privacy_no_path_to_user
  attr_privacy :id, :title, :servings, :description, :active_time, :total_time, :recipe_tip, :make_ahead_tip, :large_image_url, :copyright_text_url, :nutrition_information, :day, :source, :is_featured, :updated_at, :recipe_url, :is_secondary_featured, :public

  set_primary_key 'id'

  has_many :recipe_steps, :dependent => :destroy
  has_many :ingredients, :dependent => :destroy
  has_many :recipe_categories, :dependent => :destroy

  acts_as_likeable :label => "Favorite"
  acts_as_commentable

  def validate
    if require_validation
      errors.add(:recipe_steps, "This recipe needs at least one recipe step") if recipe_steps.empty?
      errors.add(:ingredients, "This recipe needs at least one ingredient") if ingredients.empty?
    end
  end
  
  def content
    recipe_content = <<-EOF
#{description}

###Ingredients
#{content_ingredients}

###Directions
#{content_directions}

#{"###Tip:" unless recipe_tip.to_s.empty?}
#{recipe_tip}

#{"###Make Ahead Tip:" unless make_ahead_tip.to_s.empty?}
#{make_ahead_tip}

###Nutrition Information
#{nutrition_information}

#{copyright_text_url}
    EOF
    return recipe_content
  end
  
  def content_ingredients
    text = ""
    ingredients.collect {|c| c.category }.uniq.each do |cat|
      unless ingredients.collect {|c| c.category }.uniq.size == 1
        text += "\n#####{cat}\n"
      end
      ingredients.select { |i| i.category==cat }.each do |i|
        text += "- #{i.to_string}\n"
      end
    end
    return text
  end
  
  def content_directions
    text = ""
    directions.each_with_index do |d,i| 
      text += "#{i+1}. #{d.description}\n"
    end
    return text
  end
  
  #path to the image file
  def image_url(host='')
    #assume we're going to use staging url
    url = "http://dashboard.staging.hesapps.com/images/recipe/#{large_image_url}"
    #if in a production mode, remove the staging url
    url = url.gsub("staging.","") unless (host.include?('staging.') || Rails.env.to_s == 'development')
    
    return url
  end
  #check to see if validation is required
  def is_required
    !is_video
  end
  
  #get the recipe steps in the correct order
  def directions
    recipe_steps.sort
  end
  
  #check to see if a recipe has been saved to the database yet
  def new?
    id.nil?
  end
  
  #compare recipes on the day they are to appear on and not their ids
  def <=> otherRecipe
    if day.nil?
      -1
    elsif otherRecipe.day.nil?
      1
    else
      day <=> otherRecipe.day
    end
  end
  
  def has_multiple_ingredient_categories
    category_count = 0
    category = ""
    ingredients.each do |i|
      unless category == i.category
        category_count = category_count + 1
        category = i.category
      end
    end
    if category_count == 1
      return false
    else
      return true
    end
  end
  
  #converts the ingredients into a string seperated by a colon.
  def ingredients_to_string
    ingredients.to_sentence
  end
  
  def course
    course = ""
    courses = recipe_categories.find(:all, :conditions => "category_type = 'meal' or category_type = 'Courses'")
    courses.each do |c|
      course += "#{c.category}&nbsp;/&nbsp;" 
    end
    if course.empty?
      courses = recipe_categories.find(:all, :conditions => "category_type = 'DishTypes'")
      courses.each do |c|
        course += "#{c.category}&nbsp;/&nbsp;" 
      end
    end
    course.chomp("&nbsp;/&nbsp;")
  end
  
  def self.find_by_meal_type(type,order=:title,limit=nil)
    find(:all,
         :include => [:recipe_categories,:ingredients,:recipe_steps],
         :conditions => "recipe_categories.category_type = 'meal' and (#{Recipe.meal_type_condition(type)})",
         :order => order,
         :limit=>limit)
  end  

  def self.find_random_by_meal_type(type,limit=5)
    self.find_by_meal_type(type,'rand()',limit)
  end
  
  def self.find_by_search_text(search_text,options={})
    search_text_sanitized = sanitize(search_text)
    wildcard_search_text_sanitized = sanitize("%#{search_text}%")
    rank_select =<<-EOF
        DISTINCT recipes.id, title,                                       
          case
          when INSTR(LCASE(title), LCASE(#{search_text_sanitized})) > 0 AND
            INSTR(LCASE(description), LCASE(#{search_text_sanitized})) > 0 AND
            INSTR(LCASE(item), LCASE(#{search_text_sanitized})) > 0 THEN 100
          when INSTR(LCASE(title), LCASE(#{search_text_sanitized})) > 0 AND
            INSTR(LCASE(description), LCASE(#{search_text_sanitized})) > 0 THEN 75
          when INSTR(LCASE(title), LCASE(#{search_text_sanitized})) > 0 THEN 75
          when INSTR(LCASE(description), LCASE(#{search_text_sanitized})) > 0 AND
            INSTR(LCASE(item), LCASE(#{search_text_sanitized})) > 0 THEN 75
          when INSTR(LCASE(description), LCASE(#{search_text_sanitized})) > 0 THEN 50
          else 0
          end AS 'rank'
        EOF
    
    default_options = {
      :joins => "INNER JOIN ingredients ON ingredients.recipe_id = recipes.id",
      :conditions => "description like #{wildcard_search_text_sanitized} or title like #{wildcard_search_text_sanitized} or ingredients.item like #{wildcard_search_text_sanitized}",
      :order => 'rank DESC, title',
      :select => "#{rank_select}, servings, description, active_time, total_time, recipe_tip, make_ahead_tip, large_image_url, copyright_text_url, nutrition_information, day, source, is_featured, updated_at, recipe_url, is_secondary_featured"
    }
    
    find(:all, default_options.merge(options))
  end
  
  def self.meal_type_condition(type)
    conditions = []
    RecipeCategory::MealTypeNames[type.to_sym].each do |name|
      conditions << "recipe_categories.category = #{sanitize(name)}"
    end
    conditions.join(' or ')
  end
  
  #get the daily recipe
  def self.daily
    # this gets a Range object with the days between jan1 and today
    # then it skips Sat and Sun, so new recipes will only appear Mon - Fri
    now = Date.today
    jan1 = now.to_time.beginning_of_year.to_date
    days = (jan1..now).select{ |day| (day.wday !=0 && day.wday != 6) }.size
    # this fails gracefully as long as there is at least one recipe for this application
    Recipe.find_by_day(days) || Recipe.find_by_day(Recipe.maximum(:day))
  end

  # Override as_json since ActiveResource seems to ignore include_root_in_json set to false on instances
  def serializable_hash(options = {})
    options[:except] = [:large_image_url]
    options[:methods] = [:image_url, :ingredients, :recipe_steps, :recipe_categories]
    super
  end

  def as_json(options = {})
    recipe_hash = super
    recipe_hash['recipe'] ? recipe_hash['recipe'] : recipe_hash
  end
end
