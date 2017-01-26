class AddHasLoggedToLevel < ActiveRecord::Migration
  def change
    add_column :levels, :has_logged, :boolean
  end
end
