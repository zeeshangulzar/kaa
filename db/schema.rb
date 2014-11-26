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

ActiveRecord::Schema.define(:version => 20141125191044) do

  create_table "activities", :force => true do |t|
    t.integer  "promotion_id"
    t.string   "name"
    t.text     "content"
    t.string   "type_of_prompt"
    t.integer  "cap_value"
    t.string   "cap_message",      :limit => 200
    t.string   "regex_validation", :limit => 20
    t.text     "options"
    t.text     "summary"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "custom_prompts", :force => true do |t|
    t.integer  "custom_promptable_id"
    t.string   "custom_promptable_type"
    t.integer  "sequence"
    t.string   "prompt",                 :limit => 500
    t.string   "data_type",              :limit => 20
    t.string   "type_of_prompt",         :limit => 20
    t.string   "short_label",            :limit => 20
    t.text     "options"
    t.boolean  "is_active",                             :default => true
    t.boolean  "is_required",                           :default => false
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at",                                               :null => false
  end

  add_index "custom_prompts", ["custom_promptable_type", "custom_promptable_id"], :name => "cp_index"

  create_table "entries", :force => true do |t|
    t.integer  "user_id"
    t.boolean  "is_recorded"
    t.date     "recorded_on"
    t.text     "notes"
    t.integer  "daily_points"
    t.integer  "challenge_points"
    t.integer  "timed_activity_points"
    t.integer  "exercise_minutes"
    t.integer  "exercise_steps"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "entries", ["user_id"], :name => "index_entries_on_user_id"

  create_table "entry_activities", :force => true do |t|
    t.integer  "entry_id"
    t.integer  "activity_id"
    t.string   "value"
    t.integer  "sequence",    :default => 0
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "entry_activities", ["activity_id"], :name => "index_entry_activities_on_activity_id"
  add_index "entry_activities", ["entry_id", "activity_id", "sequence"], :name => "index_entry_activities_on_entry_id_and_activity_id_and_sequence", :unique => true
  add_index "entry_activities", ["entry_id"], :name => "index_entry_activities_on_entry_id"

  create_table "evaluation_definitions", :force => true do |t|
    t.integer  "eval_definitionable_id"
    t.string   "eval_definitionable_type"
    t.string   "name"
    t.integer  "days_from_start"
    t.integer  "sequence"
    t.text     "message"
    t.text     "visible_questions"
    t.integer  "flags_1",                  :default => 126
    t.integer  "flags_2",                  :default => 134096128
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
  end

  add_index "evaluation_definitions", ["eval_definitionable_id", "eval_definitionable_type"], :name => "eval_def_idx"

  create_table "evaluation_udfs", :force => true do |t|
    t.integer "evaluation_id"
  end

  add_index "evaluation_udfs", ["evaluation_id"], :name => "by_evaluation_id"

  create_table "evaluations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "evaluation_definition_id"
    t.integer  "days_active_per_week"
    t.integer  "fruit_servings"
    t.integer  "vegetable_servings"
    t.integer  "fruit_vegetable_servings"
    t.integer  "whole_grains"
    t.integer  "breakfast"
    t.string   "stress",                   :limit => 9
    t.string   "sleep_hours",              :limit => 11
    t.string   "social",                   :limit => 9
    t.integer  "water_glasses"
    t.text     "liked_most",               :limit => 255
    t.integer  "kindness"
    t.string   "energy",                   :limit => 16
    t.string   "overall_health",           :limit => 9
    t.text     "liked_least",              :limit => 255
    t.string   "exercise_per_day"
    t.string   "perception"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  add_index "evaluations", ["evaluation_definition_id"], :name => "index_evaluations_on_evaluation_definition_id"
  add_index "evaluations", ["user_id"], :name => "index_evaluations_on_user_id"

  create_table "exercise_activities", :force => true do |t|
    t.integer  "promotion_id"
    t.string   "name"
    t.text     "summary"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "exercise_activities", ["promotion_id"], :name => "index_exercise_activities_on_promotion_id"

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

  create_table "point_thresholds", :force => true do |t|
    t.integer  "pointable_id"
    t.string   "pointable_type"
    t.integer  "value"
    t.integer  "min"
    t.text     "rel"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "gender",          :limit => 1
    t.integer  "goal"
    t.string   "first_name",      :limit => 100
    t.string   "last_name",       :limit => 100
    t.string   "phone",           :limit => 30
    t.string   "mobile_phone",    :limit => 11
    t.string   "line1",           :limit => 150
    t.string   "line2",           :limit => 150
    t.string   "city",            :limit => 150
    t.string   "state_province",  :limit => 150
    t.string   "country",         :limit => 150
    t.string   "postal_code",     :limit => 150
    t.string   "time_zone"
    t.string   "employee_group",  :limit => 50
    t.string   "employee_entity", :limit => 50
    t.date     "started_on"
    t.date     "registered_on"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
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

  create_table "tiles", :force => true do |t|
    t.integer  "activities_id"
    t.string   "title",         :limit => 50
    t.string   "description",   :limit => 250
    t.string   "image"
    t.boolean  "default",                      :default => false
    t.integer  "default_seq"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
  end

  create_table "timed_activities", :force => true do |t|
    t.integer  "activity_id"
    t.date     "begin_date"
    t.date     "end_date"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "udf_defs", :force => true do |t|
    t.string  "owner_type",  :limit => 30
    t.string  "parent_type", :limit => 30
    t.integer "parent_id"
    t.string  "data_type"
    t.boolean "is_enabled",                :default => true
  end

  add_index "udf_defs", ["parent_type", "parent_id"], :name => "by_parent_type_parent_id"

  create_table "user_tiles", :force => true do |t|
    t.integer  "users_id"
    t.integer  "tiles_id"
    t.integer  "sequence"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.integer  "promotion_id"
    t.integer  "location_id"
    t.integer  "top_level_location_id"
    t.integer  "organization_id"
    t.integer  "reseller_id"
    t.integer  "map_id"
    t.string   "role",                  :limit => 50
    t.string   "username",              :limit => 50
    t.string   "password",              :limit => 64
    t.string   "password_hash",         :limit => 64
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
