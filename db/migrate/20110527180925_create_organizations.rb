class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.references  :reseller
      t.string      :name,                          :limit => 100
      t.string      :wskey,                         :limit => 36
      t.boolean     :is_sso_enabled,                :default => false
      t.boolean     :is_hes_info_removed,           :default => false
      t.string      :sso_label,                     :limit => 100
      t.string      :sso_login_url,                 :sso_redirect
      t.boolean     :password_ignores_case,         :default => false
      t.integer     :password_min_length,           :default => 4
      t.integer     :password_max_length,           :default => 20
      t.integer     :password_min_letters, :password_min_numbers, :password_min_symbols, :default => 0
      t.integer     :password_max_attempts,         :default => 5
      t.string      :customized_path,               :default => 'default'

      t.timestamps
    end
  end
end
