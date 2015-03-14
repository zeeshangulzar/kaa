class CreateDemographics < ActiveRecord::Migration
  def up
    create_table :demographics do |t|
      t.integer     :user_id
      t.string      :gender,    :limit => 1
      t.string      :ethnicity
      t.string      :age
      t.timestamps
    end
  end
  def down
  end
end
