class CreatePosters < ActiveRecord::Migration
  def change
    create_table :posters do |t|
      t.integer     :promotion_id
      t.string      :title
      t.string      :summary
      t.string      :content
      t.string      :image1
      t.string      :image2
      t.string      :image3
      t.string      :image4
      t.integer     :success_story_id
      t.boolean     :active
      t.datetime    :visible_date
      t.timestamps
    end
  end
end
