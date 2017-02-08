class AddMoreImagesToDestinations < ActiveRecord::Migration
  def change
    add_column :destinations, :image4, :string, :length => 255, :default => nil
    add_column :destinations, :image4_caption, :string, :length => 255, :default => nil
    add_column :destinations, :image5, :string, :length => 255, :default => nil
    add_column :destinations, :image5_caption, :string, :length => 255, :default => nil
  end
end
