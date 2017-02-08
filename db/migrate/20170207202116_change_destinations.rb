class ChangeDestinations < ActiveRecord::Migration
  def change
    add_column :destinations, :quote_text, :string, :length => 255, :default => nil
    add_column :destinations, :quote_name, :string, :length => 255, :default => nil
    add_column :destinations, :quote_image, :string, :length => 255, :default => nil
    add_column :destinations, :quote_caption, :string, :length => 255, :default => nil
  end
end
