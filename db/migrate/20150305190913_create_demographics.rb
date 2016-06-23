class CreateDemographics < ActiveRecord::Migration
  def up
    create_table :demographics do |t|
      t.integer     :user_id
      t.string      :gender,    :limit => 1
      t.string      :ethnicity, :limit => 30
      t.integer     :age, :limit => 3
      t.timestamps
    end
  end
  def down
  end
end
