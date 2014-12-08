class CreateChallenges < ActiveRecord::Migration
  def change
    create_table :challenges do |t|
      t.integer :promotion_id
      t.integer :location_id
      t.text    :name
      t.text    :description
      t.integer :created_by
      t.integer :last_updated_by
      t.date    :visible_from
      t.date    :visible_to
      t.timestamps
    end
  end
end
