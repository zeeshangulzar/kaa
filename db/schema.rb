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

ActiveRecord::Schema.define(:version => 20141118165214) do

  create_table "flag_defs", :force => true do |t|
    t.string  "model",     :limit => 100
    t.integer "position"
    t.string  "flag_name", :limit => 100
    t.text    "flag_type", :limit => 255
    t.boolean "default",                  :default => false
  end

  add_index "flag_defs", ["model"], :name => "by_model"

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
    t.string   "contact_name",          :limit => 100
    t.string   "contact_email",         :limit => 100
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
  end

  create_table "profile_udfs", :force => true do |t|
    t.integer "profile_id"
  end

  add_index "profile_udfs", ["profile_id"], :name => "by_profile_id"

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "gender",             :limit => 1
    t.integer  "goal"
    t.string   "first_name",         :limit => 100
    t.string   "last_name",          :limit => 100
    t.string   "phone",              :limit => 30
    t.string   "mobile_phone",       :limit => 11
    t.string   "line1",              :limit => 150
    t.string   "line2",              :limit => 150
    t.string   "city",               :limit => 150
    t.string   "state_province",     :limit => 150
    t.string   "country",            :limit => 150
    t.string   "postal_code",        :limit => 150
    t.string   "time_zone"
    t.integer  "days_active_per_wk"
    t.string   "exercise_per_day",   :limit => 50
    t.string   "employee_group",     :limit => 50
    t.string   "employee_entity",    :limit => 50
    t.date     "started_on"
    t.date     "registered_on"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "flags_1",                           :default => 0
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
    t.string   "name",          :limit => 100
    t.string   "contact_name",  :limit => 100
    t.string   "contact_email", :limit => 100
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  create_table "udf_defs", :force => true do |t|
    t.string  "owner_type",  :limit => 30
    t.string  "parent_type", :limit => 30
    t.integer "parent_id"
    t.string  "data_type"
    t.boolean "is_enabled",                :default => true
  end

  add_index "udf_defs", ["parent_type", "parent_id"], :name => "by_parent_type_parent_id"

  create_table "users", :force => true do |t|
    t.integer  "promotion_id"
    t.integer  "location_id"
    t.integer  "top_level_location_id"
    t.integer  "organization_id"
    t.integer  "reseller_id"
    t.integer  "map_id"
    t.string   "role",                  :limit => 50
    t.string   "username",              :limit => 50
    t.string   "password",              :limit => 50
    t.string   "auth_key"
    t.string   "sso_identifier",        :limit => 100
    t.boolean  "allows_email",                         :default => true
    t.string   "altid",                 :limit => 50
    t.string   "email",                 :limit => 100
    t.datetime "last_login"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

end
