require 'hes-contact-requests/engine'

# Supplies a contact requests controller and a way to easily hook in a ticket generator
module HesContactRequests
  mattr_accessor :ticket
  mattr_accessor :backup_ticket
end
