class AddImageToChallenges < ActiveRecord::Migration
  def change
    add_column :challenges, :image, :string, :default => nil
  end
end
