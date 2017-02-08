class AddImagesToDestinations < ActiveRecord::Migration
  def change
    add_column :destinations, :image1, :string, :length => 255, :default => nil
    add_column :destinations, :image1_caption, :string, :length => 255, :default => nil
    add_column :destinations, :image2, :string, :length => 255, :default => nil
    add_column :destinations, :image2_caption, :string, :length => 255, :default => nil
    add_column :destinations, :image3, :string, :length => 255, :default => nil
    add_column :destinations, :image3_caption, :string, :length => 255, :default => nil
  end
end
