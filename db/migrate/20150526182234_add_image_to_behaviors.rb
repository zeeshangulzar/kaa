class AddImageToBehaviors < ActiveRecord::Migration
  def change
    add_column :behaviors, :image, :text
  end
end
