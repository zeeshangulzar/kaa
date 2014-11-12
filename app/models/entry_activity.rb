# Many to many class that ties Entry and Recording Activity together
class EntryActivity < ActiveRecord::Base
  belongs_to :entry
  belongs_to :activity
  
  attr_accessible :value, :entry_id, :activity_id

  before_save :clear_value_if_empty

  # Sets the value to zero if it is an empty string
  def clear_value_if_empty
    write_attribute(:value, nil) if self.value.is_a?(String) && self.value.empty?
  end
end
