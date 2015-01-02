require "hes-authorization"
#require "hes-api"
#require "hes-central"
#require "hes-likeable"
# require "hes-commentable"

#require File.dirname(__FILE__) + '/recipe-generator'

module HesRecipes

  # Engine to initialize HesRecipes
  class Engine < ::Rails::Engine

    initializer "HesRecipes" do |app|
      # Add code here to initialize HesRecipes
    end

 #   config.generators do |g|
 #     g.test_framework :rspec, :view_specs => false
 #   end
  end

end
