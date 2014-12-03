class CreateChallengesSent < ActiveRecord::Migration
  def change
    create_table :challenges_sent do |t|
      t.integer :user_id
      t.integer :challenge_id
      t.integer :to_user_id
      t.integer :to_group_id
      t.timestamps
    end
  end
end
