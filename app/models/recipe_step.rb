class RecipeStep < ActiveRecord::Base
  belongs_to :recipe

  set_primary_key 'id'

  attr_privacy_no_path_to_user
  attr_privacy :id, :recipe_id, :description, :is_optional, :sequence, :public
  
  def <=> otherStep
    if sequence.nil?
      -1
    elsif otherStep.sequence.nil?
      1
    else
      sequence <=> otherStep.sequence
    end
  end

end
