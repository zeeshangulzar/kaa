class AddIsEligibleForRewardsToProfile < ActiveRecord::Migration
  def change
    add_column :users, :nuid_verified, :boolean, :default => false
  end
end
