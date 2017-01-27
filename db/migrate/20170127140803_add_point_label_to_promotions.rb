class AddPointLabelToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :point_label, :string, :default => 'point'
  end
end
