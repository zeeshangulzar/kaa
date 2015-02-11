class Ingredient < ActiveRecord::Base
  belongs_to :recipe

  set_primary_key 'id'

  attr_privacy_no_path_to_user
  attr_privacy :id, :recipe_id, :quantity, :unit, :item, :note, :measure_type, :brand, :category, :public

  def to_string
     ing_text = ""
     ing_text += "#{quantity} " unless quantity.to_s.empty?
     ing_text += "#{unit} of " unless unit.to_s.empty? or unit == "each"
     ing_text += item unless item == "n/a"
     ing_text += note[0..0] == "," ? note : " #{note}"
     ing_text += " #{measure_type}" unless measure_type.nil?
     ing_text += " #{brand}" unless brand.nil?
     ing_text
  end

end
