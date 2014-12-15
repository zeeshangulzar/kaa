class CreateChallengesReceived < ActiveRecord::Migration
  def change
    create_table :challenges_received do |t|
      t.integer   :challenge_id
      t.integer   :user_id
      t.integer   :status
      t.date      :expires_on
      t.datetime  :completed_on
      t.text      :notes
      t.timestamps
    end
  end
end
