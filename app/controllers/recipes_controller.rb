class RecipesController < ApplicationController
  authorize :index, :show, :search, :browse, :user
  
  before_filter :page_settings
  def page_settings
    cookies[:last_recipe_visit] = Date.today
  end
  private :page_settings
  
  def index
    HESResponder Recipe.includes(:recipe_categories,:ingredients,:recipe_steps).all
  end

  def show
    if params[:daily]
      recipe = Recipe.daily
    elsif params[:first]   
      # this is probably unnecessary 
      recipe = Recipe.find(Recipe.minimum(:id))
    elsif params[:last]
      # this is probably unnecessary 
      recipe = Recipe.find(Recipe.maximum(:id))
    else
      recipe = Recipe.find(params[:id])
    end
    HESResponder recipe
  end
  
  def browse
    chosen = params[:category].downcase
    available = RecipeCategory::MealTypes
    if available.include?(chosen)
      recipes = Recipe.find_by_meal_type(chosen)
      HESResponder recipes
    else
      HESResponder("'#{params[:category]}' is not a category.  Categories are #{available.join(', ')}.", "ERROR") 
    end
  end
  
  # NOTE: this does NOT return recipes.  it returns ids and titles and rank; enough to display a seach result
  #         - i.e. if you search for 'veal' then veal in the title is ranked higher than veal as an ingredient
  #             - sorting by that rank is better than sorting by title alphabetically
  #         - there are ONLY 260 recipes.... maybe the client can get all 260 and do the filtering by itself
  def search
    recipes = Recipe.find_by_search_text(params[:search]).uniq.collect{|r|{:id=>r.id,:title=>r.title,:rank=>r.rank}}
    HESResponder recipes
  end
end
