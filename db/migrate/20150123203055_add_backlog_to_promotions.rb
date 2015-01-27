class AddBacklogToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :backlog_days, :integer
  end
end
