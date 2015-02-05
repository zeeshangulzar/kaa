class AddCanceledToEvents < ActiveRecord::Migration
  def change
    add_column :events, :is_canceled, :boolean, :default => false
  end
end
