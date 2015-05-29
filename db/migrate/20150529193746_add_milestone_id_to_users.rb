class AddMilestoneIdToUsers < ActiveRecord::Migration
  def up
    add_column :users, :milestone_id, :integer
    sql = "
      UPDATE users
      JOIN (
        SELECT 
          user_badges.user_id, max(user_badges.earned_date), user_badges.badge_id, badges.name
        FROM `badges` 
          INNER JOIN `user_badges` ON `badges`.`id` = `user_badges`.`badge_id`
        WHERE 
          badges.badge_type = 'milestone' AND YEAR(earned_date) = 2015
        GROUP BY user_badges.id
        ORDER BY user_id ASC, earned_date DESC, badges.sequence DESC
      ) x
      ON x.user_id = users.id
      SET users.milestone_id = x.badge_id"
    self.connection.execute(sql)
  end
  def down
    remove_column :users, :milestone_id
  end
end
