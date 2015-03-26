class CreateBanners < ActiveRecord::Migration
  def change
    create_table :banners do |t|
      t.integer :promotion_id
      t.integer :location_id
      t.text    :image
      t.text    :link_url
      t.text    :description
      t.string  :name
      t.timestamps
    end
  end
end
