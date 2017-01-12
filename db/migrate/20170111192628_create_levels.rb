class CreateLevels < ActiveRecord::Migration
  def change
    create_table :levels do |t|
      t.references :promotion
      t.string    :name
      t.integer   :min
      t.timestamps
    end
  end
end
