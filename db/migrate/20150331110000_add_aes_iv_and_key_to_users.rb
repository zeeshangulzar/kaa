class AddAesIvAndKeyToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :aes_key, :string
    add_column :users, :aes_iv, :string
  end
 
  def self.down
    remove_column :users, :aes_iv
    remove_column :users, :aes_key
  end

end
