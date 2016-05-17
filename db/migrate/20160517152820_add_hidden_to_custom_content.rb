class AddHiddenToCustomContent < ActiveRecord::Migration
  def up
    add_column :custom_content, :hidden, :boolean
    add_column :custom_content_archive, :hidden, :boolean
  end
  def down
    remove_column :custom_content, :hidden
    remove_column :custom_content_archive, :hidden
  end
end
