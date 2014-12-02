class CreatePointThresholdsTable < ActiveRecord::Migration
  def change
    create_table :point_thresholds do |t|
      t.references :pointable, :polymorphic => true
      t.integer :value
      t.integer :min
      t.text :rel
      t.text :color, :limit => 10 

      t.timestamps
    end   
  end
end