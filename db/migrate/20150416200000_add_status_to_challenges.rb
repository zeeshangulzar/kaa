class AddStatusToChallenges < ActiveRecord::Migration
  def change
    add_column :challenges, :status, :integer, :default => 2
  end
end
