class CreateCustomContentArchive < ActiveRecord::Migration
  def change
    create_table :custom_content_archive do |t|
      t.references  :custom_content, :promotion, :location
      t.string    :category
      t.string    :key
      t.string    :title
      t.text      :description
      t.text      :summary
      t.text      :content
      t.string    :title_html
      t.text      :description_html
      t.text      :summary_html
      t.text      :content_html
      t.string    :image
      t.text      :caption
      t.text      :caption_html
      t.integer   :sequence
      t.datetime  :archived_at
      t.timestamps
    end
    add_index :custom_content_archive, :promotion_id
    add_index :custom_content_archive, :category
  end
end
