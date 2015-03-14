class JawboneViews < ActiveRecord::Migration
  def self.up
     HESJawbone::get_create_view_sql.each do |cv|
      execute cv
    end
  end

  def self.down
  end
end
