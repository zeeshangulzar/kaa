class AddStuffToUsers < ActiveRecord::Migration
  def change
    add_column :users, :opted_in_individual_leaderboard, :boolean, :default => true
  end
end
