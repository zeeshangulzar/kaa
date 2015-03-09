class CreateForums < ActiveRecord::Migration
  def change
    create_table :forums do |t|
      t.integer     :location_id
      t.string      :name
      t.text        :summary
      t.text        :content
      t.string      :image
      t.integer     :sequence
      t.timestamps
    end
  end
end
