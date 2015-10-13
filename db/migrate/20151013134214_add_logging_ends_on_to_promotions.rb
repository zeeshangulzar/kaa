class AddLoggingEndsOnToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :logging_ends_on, :date
    add_column :promotions, :disabled_on, :date
  end
end
