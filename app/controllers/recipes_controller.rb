# Controller get getting recipes. Not used for creating, updating, or destroying.
class RecipesController < ApplicationController


  authorize :index, :user
  authorize :show, :public

  # Get all recipes
  #
  # @url [GET] /recipes
  # @url [GET] /recipes?browse=breakfast
  # @url [GET] /recipes?query=chicken
  # @authorize User
  # @param [String] browse The meal type of recipes to return. Example values: breakfast, lunch, dinner, snacks
  # @param [String] query The search terms to find matching recipes
  # @return [Array<Recipe>] Array of recipes
  #
  # [URL] /recipes [GET]
  #  [200 OK] Successfully return array of Recipes
  #   # Example response
  #   [{
  #     "id": 1,
  #     "copyright_text_url": "text",
  #     "recipe_steps": [{
  #       "sequence": 1,
  #       "description": "Stir in broth, squash, thyme and cumin; cover and bring to a boil.",
  #       "is_optional": false
  #     }],
  #     "nutrition_information": "300 calories per serving...",
  #     "servings": "text",
  #     "ingredients": [{
  #       "text" => "1 cup of sugar"
  #     }],
  #     "active_time": "text",
  #     "recipe_batch_id": 1,
  #     "total_time": "30 minutes",
  #     "title": "Chicken Broccoli",
  #     "recipe_url": "http://www.eatingwall.com/chicken_broccoli.html",
  #     "recipe_categories": [{
  #       "category": 'Breakfast',
  #       "category_type": 'Meal'
  #     }],
  #     "large_image_url": "http://www.eatingwall.com/chicken_broccoli.jpg",
  #     "is_active": true,
  #     "description": "This Southwestern-inspired turkey-and-squash soup gets a little kick from crushed red pepper and some zing from fresh lime juice...",
  #     "make_ahead_tip": "Marinade the chicken overnight in soy sauce",
  #     "recipe_tip": "Pick the freshest chicken at the farmers market",
  #     "source": "EatingWell.com"
  #   }]
  def index
    @recipes = params[:browse].nil? && params[:query].nil? ? [] : params[:browse].nil? ? Recipe.find_all_by_search(params[:query]).uniq : Recipe.find_all_by_meal_type(params[:browse])
    return HESResponder(@recipes)
  end

  # Get Individual Recipe or Daily Recipe
  #
  # @url [GET] /recipes/1
  # @url [GET] /recipes/daily
  # @authorize Public
  # @param [Integer, String] id The id of the recipe, can also be "daily" to return the recipe for today
  # @return [Recipe] Recipe that matches id or is daily recipe
  #
  # [URL] /recipes/:id [GET]
  #  [200 OK] Successfully return a Recipe
  #   # Example response
  #   {
  #     "id": 1,
  #     "copyright_text_url": "text",
  #     "recipe_steps": [{
  #       "sequence": 1,
  #       "description": "Stir in broth, squash, thyme and cumin; cover and bring to a boil.",
  #       "is_optional": false
  #     }],
  #     "nutrition_information": "300 calories per serving...",
  #     "servings": "text",
  #     "ingredients": [{
  #       "text" => "1 cup of sugar"
  #     }],
  #     "active_time": "text",
  #     "recipe_batch_id": 1,
  #     "total_time": "30 minutes",
  #     "title": "Chicken Broccoli",
  #     "recipe_url": "http://www.eatingwall.com/chicken_broccoli.html",
  #     "recipe_categories": [{
  #       "category": 'Breakfast',
  #       "category_type": 'Meal'
  #     }],
  #     "large_image_url": "http://www.eatingwall.com/chicken_broccoli.jpg",
  #     "is_active": true,
  #     "description": "This Southwestern-inspired turkey-and-squash soup gets a little kick from crushed red pepper and some zing from fresh lime juice...",
  #     "make_ahead_tip": "Marinade the chicken overnight in soy sauce",
  #     "recipe_tip": "Pick the freshest chicken at the farmers market",
  #     "source": "EatingWell.com"
  #   }
  def show
    @recipe = params[:daily] ? Recipe.daily : Recipe.find(params[:id]) rescue nil
    if !@recipe
      return HESResponder("Recipe", "NOT_FOUND")
    end
    return HESResponder(@recipe)
  end
end
