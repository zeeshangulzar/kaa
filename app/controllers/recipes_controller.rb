class RecipesController < ApplicationController
  authorize :index, :show, :search, :browse, :public
  
  before_filter :page_settings
  def page_settings
    cookies[:last_recipe_visit] = Date.today
  end
  private :page_settings
  
  def index
    # TODO: CC
    return HESResponder(Recipe.includes(:recipe_categories,:ingredients,:recipe_steps).all)
  end

  def show
    # TODO: CC
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
    return HESResponder(recipe)
  end
  
  def browse
    # TODO: CC
    chosen = params[:category].downcase
    available = RecipeCategory::MealTypes
    if available.include?(chosen)
      recipes = Recipe.find_by_meal_type(chosen)
      return HESResponder(recipes)
    else
      return HESResponder("'#{params[:category]}' is not a category.  Categories are #{available.join(', ')}.", "ERROR")
    end
  end
  
  # NOTE: this does NOT return recipes.  it returns ids and titles and rank; enough to display a seach result
  #         - i.e. if you search for 'veal' then veal in the title is ranked higher than veal as an ingredient
  #             - sorting by that rank is better than sorting by title alphabetically
  #         - there are ONLY 260 recipes.... maybe the client can get all 260 and do the filtering by itself
  # NOTE2: the above is no longer the case..
  #         in order to stay consistent with the other endpoints and make it easier on the frontend, just return everything, ordered by rank
  #         although this may likely be a spot to improve speed at a later date if/when necessary
  def search
    recipes = Recipe.find_by_search_text(params[:search]).uniq.sort{|a,b|a.rank <=> b.rank }.reverse
    return HESResponder(recipes)
  end
end
