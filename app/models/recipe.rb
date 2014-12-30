# ActiveResource model of recipes
class Recipe < HesCentral::CentralResource
  require 'rest_client'
  self.include_root_in_json = false

  acts_as_likeable :label => "Favorite"
  acts_as_commentable

  attr_accessor :recipe_categories, :ingredients, :recipe_steps

  # Gets all recipes
  # @return [Array<Recipe>] all recipes
  # @note Not recommended to use this method since it will return a lot of data
  def self.all
    get('all', {}, true)
  end

  # Finds all recipes with a title, ingredient, or description matching the search query
  # @param [String] query to search recipes for
  # @return [Array<Recipe>] all recipes that match the query
  def self.find_all_by_search(query)
    get('search', {
          :query => query
    }, true)
  end

  # Finds all recipes with a certain meal type
  # @param [String] meal_type of recipes
  # @return [Array<Recipe>] all recipes that match the meal type
  def self.find_all_by_meal_type(meal_type)
    get('by_category', {
          :meal_type => meal_type
    }, true)
  end

  # Gets the recipe that matches the ID
  # @param [Integer] id of the recipe
  # @return [Recipe] found recipe
  def self.find(id)
    get(id)
  end

  # Gets the first recipe
  # @return [Recipe] first recipe
  def self.first
    get('first')
  end

  # Gets the last recipe
  # @return [Recipe] last recipe
  def self.last
    get('last')
  end

  # Gets the recipe that has been specifed for today or the day passed in
  # @param [Integer] day that recipe is needed for, defaults to today
  # @return [Recipe] recipe that matches the day
  # @note Returns the last recipe if no recipes match the day
  def self.daily(day = get_day)
    get("daily/#{day}")
  rescue RestClient::ResourceNotFound
    Recipe.last
  end

  # Raise an error since recipes should only be saved in central application
  def save(*args)
    raise "Recipe cannot be saved from ActiveResource"
  end

  # Raise an error since recipes should only be created in central application
  def create(*args)
    raise "Recipe cannot be created from ActiveResource"
  end

  def initialize(*args)

    @recipe_categories = (args[0].delete("recipe_categories") || []).collect{|x| RecipeCategory.new(x)}
    @recipe_steps = (args[0].delete("recipe_steps") || []).collect{|x| RecipeStep.new(x)}
    @ingredients = (args[0].delete("ingredients") || []).collect{|x| Ingredient.new(x)}

    super
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

  def image_url
    #assume we're going to use staging url
    url = "http://dashboard.staging.hesapps.com/images/recipe/#{large_image_url}"
    #if in a production mode, remove the staging url
    url = url.gsub("staging.","") unless Rails.env.development? || Rails.env.test? || (defined?(IS_STAGING) && IS_STAGING)
    
    return url
  end


  private

  # Gets the recipes from the central HES application
  # @param [String] path that will be appended to app_recipes central url
  # @param [Hash] params that will be turned into a query string and appended to url
  # @param [Boolean] plural should be true if array is returned, false if just one is expected, defaults to false
  def self.get(path, params = nil, plural = false)
    path = path == "all" ? "" : "/#{path}"
    params = "&#{CGI.unescape(params.to_query)}" if params

    url = "#{Recipe.site.to_s.gsub("http://", "http://#{Recipe.user}:#{Recipe.password}@")}/app_recipes#{path}.xml?app_name=#{HesCentral.application_repository_name}#{params}"

    xml_recipes_doc = RestClient.get(url)

    unless plural
      Recipe.new(Hash.from_xml(xml_recipes_doc)['recipe'])
    else
      Hash.from_xml(xml_recipes_doc).values.first.collect{|x| Recipe.new(x)}
    end
  end

  # Gets the curent day using a Range object with the days between jan1 and today then it skips Sat and Sun, so new recipes will only appear Mon - Fri
  # @param [Date] current_date to find the day of the year, defaults to today
  # @return [Integer] day of the year skipping weekends
  def self.get_day(current_date = Date.today)
    now = current_date
    jan1 = now.to_time.beginning_of_year.to_date

    (jan1..now).select{ |day| (day.wday != 0 && day.wday != 6) }.size
  end
end
