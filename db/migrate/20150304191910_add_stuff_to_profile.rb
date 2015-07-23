class AddStuffToProfile < ActiveRecord::Migration
  def up
    add_column :profiles, :shirt_size, :string
  end
  def down
    remove_column :profiles, :shirt_size
  end
end
