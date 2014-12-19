class AddNameToSuggestedChallenge < ActiveRecord::Migration
  def change
    add_column :suggested_challenges, :name, :string
  end
end
