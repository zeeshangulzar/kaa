class AddStatusToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :status, :integer, :default => 1 #active
    add_column :promotions, :version, :string
    add_column :users, :backdoor, :boolean, :default => false
  end
end
