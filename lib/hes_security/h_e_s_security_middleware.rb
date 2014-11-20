# authentication and authorization in 1 middleware component
class HESSecurityMiddleware
  def initialize(app,*args)
    @@disabled = false
    @app = app
  end

  def call(env)
    begin
      request = AuthBasicRequest.new(env)

      authenticate(request)

      response_code = authorize(request,env)
      if response_code
        Rails.logger.warn "    HES Security - authorization failed. returning #{response_code}"
        return [response_code,{},''] 
      else
        return @app.call(env)
      end
    ensure
      finalize_request
    end
  end

  def authenticate(request)
    @@authenticated_user = nil
    # examine request for a basic authorization HTTP header, and examine that header for a user_id and auth_key
    if request.authorization
      user_id,auth_key = request.user_name_and_password(request)
      user = User.find(:first,:conditions=>{:id => user_id.to_i, :auth_key => auth_key}) rescue nil
      self.class.set_current_user(user)
    end
    if @@authenticated_user
      Rails.logger.warn "    HES Security - authenticated user is: User##{@@authenticated_user.id}"
    else
      Rails.logger.warn "    HES Security - no authenticated user"
    end
  end

  class AuthBasicRequest < Rack::Request
    include ActionController::HttpAuthentication::Basic
    def authorization
      env['HTTP_AUTHORIZATION']   ||
      env['X-HTTP_AUTHORIZATION'] ||
      env['X_HTTP_AUTHORIZATION'] ||
      env['REDIRECT_X_HTTP_AUTHORIZATION']
    end
  end
 
  def authorize(request,env)
    # examine request:
    #   what controller + action is the user going to?
    #   if there isn't such a controller, return 404
    #   constantize that controller and process its rules
    #     - if that returns true, then they're allowed to proceed, so return nil
    #     - if that returns false, then they're not allowed to proceed, so return a response code of 403
    uri = URI::parse(request.url)
    path = uri.path
    env[:method] ||= env['REQUEST_METHOD']  # Rails.application.routes.recognize_path looks for :method not 'REQUEST_METHOD' -- so add it.
    route_hash = Rails.application.routes.recognize_path(path,env) rescue {}
    controller = route_hash[:controller]
    action = route_hash[:action]
    Rails.logger.warn "    HES Security - user is attempting to access controller:#{controller||'unknown'} action:#{action||'unknown'} via #{request.url}"

    if controller && action
      controller_classified = "#{controller.classify.pluralize}Controller"
      controller_constant = Object.const_get(controller_classified) rescue nil
      if controller_constant
        user = self.class.current_user
        promotion = user.promotion if user
        if HESControllerMixins.authorize_action(controller_constant, action, user, promotion, request.params)
          return nil
        else
          return 403
        end
      else
        Rails.logger.warn "    HES Security - controller #{controller_classified} not found"
        return 404
      end
    else
      return 404
    end

    return 403 # ensure we don't accidentally fall through...
  end
 
  def finalize_request
    @@authenticated_user = nil
    Rails.logger.debug "    HES Security - cleared authenticated user"
  end

  def self.current_user
    @@authenticated_user ||= nil
    @@authenticated_user
  end

  def self.set_current_user(user)
    @@authenticated_user = user 
  end

  def self.disabled?
    @@disabled ||= (ENV['HES_SECURITY_DISABLED']=='true' || false)
    @@disabled == true
  end

  def self.disable!
    @@disabled = true
  end
end
