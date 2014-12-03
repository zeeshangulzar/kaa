require 'hes-many_to_many'
require 'hes-authorization'
require File.dirname(__FILE__) + '/has_locations'
require File.dirname(__FILE__) + '/assigned_to_location'

module HesLocations
  # Engine for mounting locations
  class Engine < ::Rails::Engine

    ActiveRecord::Base.send :include, HesLocations::HasHesLocations
    ActiveRecord::Base.send :include, HesLocations::AssignedToLocation

  end
end
