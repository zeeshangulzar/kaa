class AddCoordinatorsToPromotion < ActiveRecord::Migration
  def up
    add_column :promotions, :coordinators, :text
  end
  def down
    remove_column :promotions, :coordinators
  end
end
