class AddNameToPointThresholds < ActiveRecord::Migration
  def up
    add_column :point_thresholds, :name, :string
  end
  def down
    remove_column :point_thresholds, :name
  end
end
