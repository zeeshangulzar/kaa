# ActiveResource model of recipe steps
class RecipeStep < HesCentral::CentralResource
  self.include_root_in_json = false
  
  # Override as_json since ActiveResource seems to ignore include_root_in_json set to false on instances
  def as_json(options = {})
    serializable_hash(options)
  end
end
