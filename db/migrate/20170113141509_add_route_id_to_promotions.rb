class AddRouteIdToPromotions < ActiveRecord::Migration
  def up
    add_column :promotions, :route_id, :integer
    add_column :promotions, :level_label, :string
  end
  def down
    remove_column :promotions, :route_id
    remove_column :promotions, :level_label
  end
end
