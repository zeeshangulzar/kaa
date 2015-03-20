class AddEndsOnToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :ends_on, :date
  end
end
