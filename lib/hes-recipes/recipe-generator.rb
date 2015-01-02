module HesRecipes
  # Creates an easy way to generate manage recipes for an HES application
  class RecipeGenerator
    
    # Adds all the recipes to dashboard.hesapps.com for the application
    # @note If run in dev or staging, will add recipes to dashboard.staging.hesapps.com
    def self.add_all
      require 'rest_client'
      RestClient.get("#{Recipe.site.to_s.gsub("http://", "http://#{Recipe.user}:#{Recipe.password}@")}/app_recipes/add_all?app_name=#{HesCentral.application_repository_name}")
    end
    
    # Destroys all the recipes from dashboard.hesapps.com for the application
    # @note If run in dev or staging, will remove recipes from dashboard.staging.hesapps.com
    def self.destroy_all
      require 'rest_client'
      RestClient.get("#{Recipe.site.to_s.gsub("http://", "http://#{Recipe.user}:#{Recipe.password}@")}app_recipes/destroy_all?app_name=#{HesCentral.application_repository_name}")
    end
  end
end
