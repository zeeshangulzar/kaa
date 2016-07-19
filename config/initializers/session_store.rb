# Be sure to restart your server when you modify this file.
require 'action_dispatch/middleware/session/dalli_store'
server = 'yo'
Go::Application.config.session_store :dalli_store, :memcache_server => server, :namespace => 'sessions', :key => '_kaa_session', :expire_after => 60.minutes