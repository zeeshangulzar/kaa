class AddSuccessStoryStuff < ActiveRecord::Migration
  def up
    add_column :success_stories, :submitted1, :text, :default => nil
    add_column :success_stories, :submitted2, :text, :default => nil
    add_column :success_stories, :submitted3, :text, :default => nil
    add_column :success_stories, :submitted4, :text, :default => nil
    add_column :success_stories, :submitted_image, :string, :default => nil
  end
  def down
    remove_column :success_stories, :submitted1
    remove_column :success_stories, :submitted2
    remove_column :success_stories, :submitted3
    remove_column :success_stories, :submitted4
    remvoe_column :success_stories, :submitted_image
  end
end
