require File.expand_path('../h_e_s_security_middleware', __FILE__)
require File.expand_path('../mixins/h_e_s_controller_mixins', __FILE__)
require File.expand_path('../mixins/h_e_s_user_mixins', __FILE__)
require File.expand_path('../h_e_s_privacy', __FILE__)

ActionController::Base.send :extend,HESControllerMixins::ClassMethods
