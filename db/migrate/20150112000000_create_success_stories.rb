class CreateSuccessStories < ActiveRecord::Migration
  def change
    create_table :success_stories do |t|
      t.string      :title
      t.string      :summary
      t.string      :content
      t.string      :image
      t.boolean     :active
      t.boolean     :featured
      t.integer     :user_id
      t.integer     :promotion_id
      t.boolean     :active
      t.timestamps
    end
  end
end
