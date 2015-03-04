class AddDefaultLoggingTypeToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :default_logging_type, :string
  end
end
