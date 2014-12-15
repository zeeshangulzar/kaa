class CreateSuggestedChallenges < ActiveRecord::Migration
  def change
    create_table :suggested_challenges do |t|
      t.integer :promotion_id
      t.text    :description
      t.integer :user_id
      t.integer :status
      t.timestamps
    end
  end
end
