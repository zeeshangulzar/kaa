require 'hes-zendesk/engine'

# Module for creating Zendesk tickets
module HesZendesk
  AuthUser = 'admin@hesapps.com'
  AuthPwd = 'H@ppytoH3lp'
end

# System that manages contact request tickets
# since zendesk isn't a gem, this has to be called after zendesk lib is loaded, hence why it's here...
HesContactRequests.ticket = HesZendesk::Ticket