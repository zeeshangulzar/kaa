class CreateChallengeSentUsers < ActiveRecord::Migration
  def up
    create_table :challenge_sent_users do |t|
      t.integer     :challenge_sent_id
      t.integer     :user_id
      t.integer     :group_id
      t.timestamps
    end
    remove_column :challenges_sent, :to_user_id
    remove_column :challenges_sent, :to_group_id
  end
end
