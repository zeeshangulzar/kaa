require 'rails_helper'
require 'hes_route_docs'

HESRouteDocs.configure do |config|
  #config.format = :json
  config.docs_dir = Rails.root.join("doc", "api")
end

def auth_basic_header
  id = "6"
  auth_key = "changeme6"
  b64 = Base64.encode64("#{id}:#{auth_key}").gsub("\n","")
  "Basic #{b64}"
end

