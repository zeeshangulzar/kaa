class CreateFlagDefs < ActiveRecord::Migration
  def change
     create_table HesFlaggable.flag_def_table_name.to_sym do |t|
        t.column "model", :string, :limit => 100
        t.column "position", :integer
        t.column "flag_name", :string, :limit => 100
        t.column "flag_type", :text, :limit => 6
        t.column "default", :boolean, :default => false
      end
      
      add_index HesFlaggable.flag_def_table_name, ["model"], :name => "by_model"
  end
end
