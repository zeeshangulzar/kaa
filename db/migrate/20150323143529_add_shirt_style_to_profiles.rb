class AddShirtStyleToProfiles < ActiveRecord::Migration
  def change
    add_column :profiles, :shirt_style, :string
  end
end
