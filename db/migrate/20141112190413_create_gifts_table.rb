class CreateGiftsTable < ActiveRecord::Migration
  def change
    create_table :gifts do |t|
      t.references :promotion
      t.string   :name
      t.text     :content
      t.text     :summary
      t.integer  :sequence
      t.string   :image
      t.timestamps
    end
  end
end
