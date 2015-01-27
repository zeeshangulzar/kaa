class LocalizeRecipesViews < ActiveRecord::Migration
  def self.up
    #execute "drop table ingredients"
    #execute "drop table recipe_categories"
    #execute "drop table recipe_color_groups"
    #execute "drop table recipe_steps"
    #execute "drop table recipes"
    execute "create view ingredients as select * from central.ingredients"
    execute "create view recipe_categories as select * from central.recipe_categories"
    execute "create view recipe_color_groups as select * from central.recipe_color_groups"
    execute "create view recipe_steps as select * from central.recipe_steps"
    execute "create view recipes as select * from central.recipes_view"
  end

  def self.down
    execute "drop view ingredients"
    execute "drop view recipe_categories"
    execute "drop view recipe_color_groups"
    execute "drop view recipe_steps"
    execute "drop view recipes"
  end
end
