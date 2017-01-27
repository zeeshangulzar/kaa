class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.references  :promotion
      t.string      :name
      t.text        :description
      t.string      :image
      t.string      :category
      t.integer     :goal
      t.integer     :minimum_program_length
      t.boolean     :hidden
      t.timestamps
    end
  end
end