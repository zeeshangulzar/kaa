require 'rails_helper'
require 'hes_route_docs'

HESRouteDocs.configure do |config|
  #config.format = :json
  config.docs_dir = Rails.root.join("public", "doc", "api")
end
