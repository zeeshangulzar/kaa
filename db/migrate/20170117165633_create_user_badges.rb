class CreateUserBadges < ActiveRecord::Migration
  def change
    create_table :user_badges do |t|
      t.references  :user, :badge
      t.integer     :earned_year
      t.date        :earned_date
      t.timestamps
    end
    add_index :user_badges, [:user_id, :badge_id, :earned_year], :name => "by_user_id_and_badge_id_and_earned_year_unique", :unique => true
  end
end