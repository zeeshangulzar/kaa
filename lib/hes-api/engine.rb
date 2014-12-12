require File.dirname(__FILE__) + '/url_attr'
require File.dirname(__FILE__) + '/respond_with_url'
require File.dirname(__FILE__) + '/hes_api_responder'
require File.dirname(__FILE__) + '/include_in_json'
require File.dirname(__FILE__) + '/accessible_attributes'
require File.dirname(__FILE__) + '/class_level_inheritable_attributes'
require File.dirname(__FILE__) + '/mark_as_destroyed'
require File.dirname(__FILE__) + '/polymorphic_alias'
require File.dirname(__FILE__) + '/get_parent'

module HESApi
  # Engine for setting up HESCustomizer
  class Engine < Rails::Engine

    #initializer "hes-api" do |app|
      ActiveRecord::Base.send :include, UrlAttr
      ActiveRecord::Base.send :include, IncludeInJSON
      ActiveRecord::Base.send :include, AccessibleAttributes
      ActiveRecord::Base.send :include, MarkAsDestroyed
      ActiveRecord::Base.send :include, PolymorphicAlias

      ActionController::Base.send :include, RespondWithUrl
      ActionController::Base.send :extend, GetParent
      ActionController::Base.responder = HESApiResponder # Custom responder but inherits from ActionController::Responder with only one method overridden
    #end

  end
end
