# using CustomBase instead of ActionController::Base saves loading unnecessary modules
class CustomBaseController < ActionController::Metal
  abstract!
  EXCLUDED_MODULES = [
    AbstractController::Layouts,
    AbstractController::Translation,
    ActionController::UrlFor,
    ActionController::ImplicitRender,
    ActionController::Flash,
    ActionController::ForceSSL,
    ActionController::Streaming,
    ActionController::RecordIdentifier,
    ActionController::RequestForgeryProtection,
    ActionController::HideActions,
    ActionController::MimeResponds
  ]
  ActionController::Base.without_modules(*EXCLUDED_MODULES).each do |left|
    puts "Including module: #{left.to_s}" unless Rails.env == 'production'
    include left
  end
  ActiveSupport.run_load_hooks(:action_controller, self)
end
