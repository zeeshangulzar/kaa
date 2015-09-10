class AddGroupToCustomContent < ActiveRecord::Migration
  def change
    add_column :custom_content, :group, :string
    add_column :custom_content_archive, :group, :string
  end
end
