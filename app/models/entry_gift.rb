# Many to many class that ties Entry and Behavior together
class EntryGift < ApplicationModel
  belongs_to :entry
  belongs_to :gift
  attr_accessible :id, :value, :entry_id, :gift_id
  attr_privacy :id, :gift_id, :value, :gift, :me
  attr_privacy_path_to_user :entry, :user

  before_save :clear_value_if_empty

  # Sets the value to zero if it is an empty string
  def clear_value_if_empty
    write_attribute(:value, nil) if self.value.is_a?(String) && self.value.empty?
  end
end
