class AddPointsToEntryBehaviors < ActiveRecord::Migration
  def change
    add_column :entry_behaviors, :points, :integer
  end
end
