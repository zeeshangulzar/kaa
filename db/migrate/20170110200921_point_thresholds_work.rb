class PointThresholdsWork < ActiveRecord::Migration
  def up
    add_column :point_thresholds, :promotion_id, :integer
    PointThreshold.all.each{|pt|
      pt.promotion_id = pt.pointable_id
      pt.pointable_type = pt.rel.downcase.classify
      pt.save!
    }
    remove_column :point_thresholds, :rel
    remove_column :point_thresholds, :color
  end
  def down
    remove_column :point_thresholds, :promotion_id
    add_column :point_thresholds, :rel, :string
    add_column :point_thresholds,:color, :string, :limit => 10
  end
end
