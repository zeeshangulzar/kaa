require File.dirname(__FILE__) + "/get_uploaded_file"

# Engine to initialize HesReactor
class Engine < ::Rails::Engine
  config.after_initialize do
  	CustomBaseController.send(:include, GetUploadedFile)
  end
end
