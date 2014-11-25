# abstraction layer between models and active record
class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true
  def all_attrs
    return *self.class.column_names
  end
end