class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.integer :promotion_id
      t.integer :location_id
      t.text    :summary
      t.text    :content
      t.text    :image
      t.timestamps
    end
  end
end
