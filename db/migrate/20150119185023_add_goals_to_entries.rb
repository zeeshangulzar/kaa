class AddGoalsToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :goal_steps, :integer
    add_column :entries, :goal_minutes, :integer
  end
end
