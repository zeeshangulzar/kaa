class AddWeeklyGoalToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :weekly_goal, :integer, :default => 12
  end
end
