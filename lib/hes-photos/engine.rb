require File.dirname(__FILE__) + "/has_photos"
module HesPhotos
  class Engine < ::Rails::Engine
    ActiveRecord::Base.send :extend, HesPhotos::HasPhotos
  end
end
