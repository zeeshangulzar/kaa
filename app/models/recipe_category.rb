class RecipeCategory < ActiveRecord::Base
  belongs_to :recipe

  set_primary_key 'id'
 
  attr_privacy_no_path_to_user
  attr_privacy :id, :recipe_id, :category_type, :category, :public
 
  MealTypes = ["breakfast","lunch","dinner","snacks"]
  MealTypeNames = {:breakfast => ["breakfast","brunch"],:lunch => ["lunch"],:dinner => ["dinner"],:snacks => ["snacks"]}
end
