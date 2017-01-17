# Many to many class that ties Entry and Behavior together
class EntryBehavior < ApplicationModel
  belongs_to :entry
  belongs_to :behavior  
  attr_accessible :id, :value, :entry_id, :behavior_id, :points
  attr_privacy :id, :behavior_id, :value, :behavior, :me
  attr_privacy_path_to_user :entry, :user

  before_save :clear_value_if_empty

  # Sets the value to zero if it is an empty string
  def clear_value_if_empty
    write_attribute(:value, nil) if self.value.is_a?(String) && self.value.empty?
  end
end
