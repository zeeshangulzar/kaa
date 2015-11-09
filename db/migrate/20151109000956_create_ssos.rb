class CreateSsos < ActiveRecord::Migration
  def up
    create_table :ssos do |t|
      t.references :promotion
      t.string :token, :limit => 32
      t.string :session_token, :limit => 50
      t.string :identifier, :first_name, :last_name, :email, :limit => 150
      t.text :data
      t.datetime :used_at
      t.timestamps
    end
    add_index :ssos,:promotion_id,:name=>'by_promotion_id'
    add_index :ssos,:token,:name=>'by_token'
    add_index :ssos,:session_token,:name=>'by_session_token'
    Organization.find(:all).each {|o| o.wskey = SecureRandom.hex(16) ; o.is_sso_enabled = o.is_hes_info_removed = false; o.save; }
  end

  def down
    drop_table :ssos
  end
end
