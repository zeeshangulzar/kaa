# Migration template for adding columns to a flaggable model
class AddFlags1ColumnToProfiles < ActiveRecord::Migration
  def change
    add_column :profiles, :flags_1, :integer, :default => 0
  end
end
