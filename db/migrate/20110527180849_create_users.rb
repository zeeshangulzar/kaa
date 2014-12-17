class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references  :promotion, :location, :top_level_location, :organization, :reseller, :map
      t.string      :role,                                            :limit => 50
      t.string      :username,                                        :limit => 50
      t.string      :password,                                        :limit => 64
      t.string      :password_hash,                                   :limit => 64
      t.string      :auth_key,                                        :limit => 255
      t.string      :sso_identifier,                                  :limit => 100
      t.boolean     :allows_email,                                    :default => true
      t.string      :altid,                                           :limit => 50
      t.string      :email,                                           :limit => 100
      t.datetime    :last_login
      t.integer     :location_id
      t.text        :tiles
      t.timestamps
    end
  end
end
