class Request < ApplicationModel
  attr_accessible *column_names
  belongs_to :user

end
