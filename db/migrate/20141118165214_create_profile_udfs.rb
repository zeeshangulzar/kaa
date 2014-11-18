# Create owner udf table
class CreateProfileUdfs < ActiveRecord::Migration
  def change
    create_table :profile_udfs, :force => true do |t|
      t.column :profile_id, :integer
    end

    connection.add_index :profile_udfs, :profile_id, :name => :by_profile_id
  end
end
