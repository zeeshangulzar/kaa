# HES Api module
module HESApi
  # Inherits from the ActionController::Responder to create a custom responder that handles the PUT and DELETE verbs differently than the default behavior
  class HESApiResponder < ActionController::Responder
    
    # Determines the api behavior for different requests depending on the verb.
    # Instead of just return OK [200] for PUT and DELETE, the resource is returned with ACCEPTED for PUT and OK for DELETE.
    # @return [String] JSON representation of model or error
    def api_behavior(error)
      if get? || has_errors? || post?
        super
      elsif put?
        display resource, :status => :accepted, :location => api_location
      else delete?
        display resource, :status => :ok, :location => api_location
      end
    end
  end
end
