class AddCategoryToChallenges < ActiveRecord::Migration
  def change
    add_column :challenges, :category, :string
    add_column :challenges, :expires_on, :date
  end
end
