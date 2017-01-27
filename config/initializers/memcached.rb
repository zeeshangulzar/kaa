require 'action_dispatch/middleware/session/dalli_store'

host =
  if Rails.env.to_s == 'development'
    'localhost:11211'
  else
    if !!defined?(IS_STAGING) && IS_STAGING
      'localhost:11211'
    else
      "#{APP_NAME_ENCODED}.memcached.hesapps.com:11211"
    end
  end

Go::Application.config.cache_store = :dalli_store, host, {:compress => true, :namespace => APP_NAME_ENCODED, :expires_in => 1.day}
Go::Application.config.session_store :dalli_store, :memcache_server => host, :namespace => 'sessions', :key => "_#{APP_NAME_ENCODED}_session", :expire_after => 60.minutes

