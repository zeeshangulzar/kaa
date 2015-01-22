require File.dirname(__FILE__) + "/get_uploaded_file"

# Engine to initialize HesReactor
class Engine < ::Rails::Engine
  config.after_initialize do
  	ActionController::Base.send(:include, GetUploadedFile)
  end
end
