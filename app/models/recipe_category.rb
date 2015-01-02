# ActiveResource model of recipe categories
class RecipeCategory < HesCentral::CentralResource
  self.include_root_in_json = false
  
  # Different types of meals
  MealTypes = ["breakfast", "lunch", "dinner", "snacks"]

  # Meal types with their possible category names
  MealTypeNames = {:breakfast => ["breakfast", "brunch"], :lunch => ["lunch"], :dinner => ["dinner"], :snacks => ["snacks"]}

  # Override as_json since ActiveResource seems to ignore include_root_in_json set to false on instances
  def as_json(options = {})
    serializable_hash(options)
  end
end
