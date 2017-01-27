class MakeBehaviorsBetter < ActiveRecord::Migration
  def up
    add_column :behaviors, :start, :date
    add_column :behaviors, :end, :date
    add_column :behaviors, :visible_start, :date
    add_column :behaviors, :visible_end, :date
    add_column :behaviors, :behaviorable_type, :string
    add_column :behaviors, :behaviorable_id, :integer
  end

  def down
  end
end
