class Request < ApplicationModel
  attr_accessible :user_id, :uri, :ip, :info, :created_at, :updated_at
  belongs_to :user

end
