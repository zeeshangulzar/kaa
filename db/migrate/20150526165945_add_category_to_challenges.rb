class AddCategoryToChallenges < ActiveRecord::Migration
  def change
    add_column :challenges, :category, :string
    add_column :challenges, :expires_on, :date
  end
  def up
    sql = "
      UPDATE challenges
      SET challenges.status = 2
      WHERE challenges.status = 1"
    self.connection.execute(sql)
  end
  def down
    sql = "
      UPDATE challenges
      SET challenges.status = 1
      WHERE challenges.status = 2"
    self.connection.execute(sql)
  end
end
