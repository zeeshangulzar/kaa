class ModifySuccessStories < ActiveRecord::Migration
  def up
    change_column :success_stories, :content, :text
    add_column :success_stories, :status, :integer, :limit => 1, :default => 0
    remove_column :success_stories, :active
  end

  def down
    change_column :success_stories, :content, :string
    remove_column :success_stories, :status
    add_column :success_stories, :active, :boolean
  end
end
