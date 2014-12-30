# ActiveResource model of ingredients
class Ingredient < HesCentral::CentralResource
  self.include_root_in_json = false
  
  # Turns the ingredient into a string
  # @return [String] ingredient in string format
  def to_string
     ing_text = ""
     ing_text += "#{quantity} " unless quantity.to_s.empty?
     ing_text += "#{unit} of " unless unit.to_s.empty? or unit == "each"
     ing_text += item unless item.nil? || item == "n/a"
     ing_text += note && note[0..0] == "," ? note : " #{note}"
     ing_text += " #{measure_type}" unless measure_type.nil?
     ing_text += " #{brand}" unless brand.nil?
     ing_text
  end

  # Overrides as_json to make sure ingredient is all return as singular string
  def as_json(options = {})
    {:text => self.to_string}
  end
end
