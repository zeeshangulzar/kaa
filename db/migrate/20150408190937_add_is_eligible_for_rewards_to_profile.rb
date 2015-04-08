class AddIsEligibleForRewardsToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :is_eligible_for_rewards, :boolean
  end
end
