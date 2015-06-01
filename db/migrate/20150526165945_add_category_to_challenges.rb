class AddCategoryToChallenges < ActiveRecord::Migration
  def up
    add_column :challenges, :category, :string
    add_column :challenges, :expires_on, :date
    sql = "
      UPDATE challenges
      SET challenges.status = 2
      WHERE challenges.status = 1"
    self.connection.execute(sql)
  end
  def down
    remove_column :challenges, :category
    remove_column :challenges, :expires_on
    sql = "
      UPDATE challenges
      SET challenges.status = 1
      WHERE challenges.status = 2"
    self.connection.execute(sql)
  end
end
