# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110527181040) do

  create_table "addresses", :force => true do |t|
    t.integer  "contact_id"
    t.string   "address_type",   :limit => 30,  :default => "main"
    t.string   "line1",          :limit => 150
    t.string   "line2",          :limit => 150
    t.string   "city",           :limit => 150
    t.string   "state_province", :limit => 150
    t.string   "country",        :limit => 150
    t.string   "postal_code",    :limit => 150
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
  end

  create_table "contacts", :force => true do |t|
    t.integer  "contactable_id"
    t.string   "contactable_type", :limit => 50
    t.string   "first_name",       :limit => 100
    t.string   "last_name",        :limit => 100
    t.string   "email",            :limit => 100
    t.string   "phone",            :limit => 30
    t.string   "mobile_phone",     :limit => 11
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "organizations", :force => true do |t|
    t.integer  "reseller_id"
    t.string   "name",                  :limit => 100
    t.string   "wskey",                 :limit => 36
    t.boolean  "is_sso_enabled",                       :default => false
    t.boolean  "is_hes_info_removed",                  :default => false
    t.string   "sso_label",             :limit => 100
    t.string   "sso_login_url"
    t.string   "sso_redirect"
    t.boolean  "password_ignores_case",                :default => false
    t.integer  "password_min_length",                  :default => 4
    t.integer  "password_max_length",                  :default => 20
    t.integer  "password_min_letters",                 :default => 0
    t.integer  "password_min_numbers",                 :default => 0
    t.integer  "password_min_symbols",                 :default => 0
    t.integer  "password_max_attempts",                :default => 5
    t.string   "customized_path",                      :default => "default"
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
  end

  create_table "promotions", :force => true do |t|
    t.integer  "organization_id"
    t.integer  "map_id"
    t.string   "name",                      :limit => 100
    t.string   "program_name",              :limit => 100
    t.string   "subdomain",                 :limit => 30
    t.string   "pilot_password",            :limit => 30
    t.string   "logo_url"
    t.integer  "max_participants"
    t.integer  "program_length"
    t.date     "launch_on"
    t.date     "starts_on"
    t.date     "registration_starts_on"
    t.date     "registration_ends_on"
    t.date     "late_registration_ends_on"
    t.boolean  "is_active",                                                               :default => false
    t.boolean  "is_archived",                                                             :default => false
    t.boolean  "is_registration_frozen",                                                  :default => true
    t.integer  "participation_x",                                                         :default => 1
    t.integer  "participation_y",                                                         :default => 7
    t.integer  "minimum_minutes_low",                                                     :default => 30
    t.integer  "minimum_minutes_medium",                                                  :default => 45
    t.integer  "minimum_minutes_high",                                                    :default => 60
    t.integer  "minimum_steps_low",                                                       :default => 6000
    t.integer  "minimum_steps_medium",                                                    :default => 8000
    t.integer  "minimum_steps_high",                                                      :default => 10000
    t.integer  "default_goal",                                                            :default => 20
    t.string   "time_zone",                                                               :default => "Eastern Time (US & Canada)"
    t.decimal  "multiplier",                                :precision => 7, :scale => 5, :default => 1.0
    t.integer  "single_day_minute_limit",                                                 :default => 90
    t.integer  "single_day_step_limit",                                                   :default => 15000
    t.string   "location_nested_labels",    :limit => 1000
    t.datetime "created_at",                                                                                                        :null => false
    t.datetime "updated_at",                                                                                                        :null => false
  end

  create_table "resellers", :force => true do |t|
    t.string   "name",       :limit => 100
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "users", :force => true do |t|
    t.integer  "promotion_id"
    t.integer  "location_id"
    t.integer  "top_level_location_id"
    t.integer  "organization_id"
    t.integer  "reseller_id"
    t.integer  "map_id"
    t.string   "role",                  :limit => 50
    t.string   "password",              :limit => 50
    t.string   "auth_key",              :limit => 255
    t.string   "sso_identifier",        :limit => 100
    t.boolean  "allows_email",                         :default => true
    t.datetime "last_login"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

end
