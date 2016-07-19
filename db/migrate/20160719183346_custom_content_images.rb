class CustomContentImages < ActiveRecord::Migration
  def up
    rename_column :custom_content, :image, :image1
    add_column :custom_content, :image2, :string
  end

  def down
    rename_column :custom_content, :image1, :image
    drop_column :custom_content, :image2
  end
end
