# abstraction layer between models and active record
class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true
end