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

ActiveRecord::Schema.define(:version => 20141222192948) do

  create_table "behaviors", :force => true do |t|
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

  create_table "challenges", :force => true do |t|
    t.integer  "promotion_id"
    t.integer  "location_id"
    t.text     "name"
    t.text     "description"
    t.string   "type",            :default => "peer"
    t.integer  "created_by"
    t.integer  "last_updated_by"
    t.date     "visible_from"
    t.date     "visible_to"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  create_table "challenges_received", :force => true do |t|
    t.integer  "challenge_id"
    t.integer  "user_id"
    t.integer  "status"
    t.datetime "expires_on"
    t.datetime "completed_on"
    t.text     "notes"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "challenges_sent", :force => true do |t|
    t.integer  "user_id"
    t.integer  "challenge_id"
    t.integer  "to_user_id"
    t.integer  "to_group_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type", :limit => 50
    t.string   "content",          :limit => 420
    t.boolean  "is_flagged",                      :default => false
    t.boolean  "is_deleted",                      :default => false
    t.datetime "last_modified_at"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
  end

  add_index "comments", ["commentable_type", "commentable_id"], :name => "commentable_idx"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

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
    t.integer  "timed_behavior_points"
    t.integer  "exercise_minutes"
    t.integer  "exercise_steps"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "entries", ["user_id"], :name => "index_entries_on_user_id"

  create_table "entry_behaviors", :force => true do |t|
    t.integer  "entry_id"
    t.integer  "behavior_id"
    t.string   "value"
    t.integer  "sequence",    :default => 0
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "entry_behaviors", ["behavior_id"], :name => "index_entry_behaviors_on_behavior_id"
  add_index "entry_behaviors", ["entry_id", "behavior_id", "sequence"], :name => "index_entry_behaviors_on_entry_id_and_behavior_id_and_sequence", :unique => true
  add_index "entry_behaviors", ["entry_id"], :name => "index_entry_behaviors_on_entry_id"

  create_table "evaluation_definitions", :force => true do |t|
    t.integer  "promotion_id"
    t.string   "name"
    t.integer  "days_from_start"
    t.integer  "sequence"
    t.text     "message"
    t.text     "visible_questions"
    t.integer  "flags_1",           :default => 126
    t.integer  "flags_2",           :default => 134096128
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
  end

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

  create_table "evaluations_udfs", :force => true do |t|
    t.integer "evaluation_id"
  end

  add_index "evaluations_udfs", ["evaluation_id"], :name => "by_evaluation_id"

  create_table "events", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",              :limit => 1
    t.string   "place",             :limit => 200
    t.boolean  "can_others_invite",                :default => false
    t.datetime "start"
    t.datetime "end"
    t.boolean  "all_day",                          :default => false
    t.string   "name",              :limit => 200
    t.text     "description"
    t.string   "privacy",           :limit => 1
    t.string   "photo"
    t.integer  "location_id"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
  end

  add_index "events", ["user_id"], :name => "index_events_on_user_id"

  create_table "exercise_activities", :force => true do |t|
    t.integer  "promotion_id"
    t.string   "name"
    t.text     "summary"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "exercise_activities", ["promotion_id"], :name => "index_exercise_activities_on_promotion_id"

  create_table "flag_defs", :force => true do |t|
    t.string  "model",     :limit => 100
    t.integer "position"
    t.string  "flag_name", :limit => 100
    t.text    "flag_type", :limit => 255
    t.boolean "default",                  :default => false
  end

  add_index "flag_defs", ["model"], :name => "by_model"

  create_table "friendships", :force => true do |t|
    t.integer  "friendee_id"
    t.string   "friendee_type"
    t.integer  "friender_id"
    t.string   "friender_type"
    t.string   "status",        :limit => 1, :default => "P"
    t.string   "friend_email"
    t.integer  "sender_id"
    t.string   "sender_type"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "friendships", ["friendee_type", "friendee_id"], :name => "friendee_idx"
  add_index "friendships", ["friender_type", "friender_id"], :name => "friender_idx"
  add_index "friendships", ["sender_type", "sender_id"], :name => "friendship_sender_idx"

  create_table "group_users", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "groups", :force => true do |t|
    t.integer  "owner_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "invites", :force => true do |t|
    t.integer  "event_id"
    t.integer  "invited_user_id"
    t.integer  "inviter_user_id"
    t.integer  "status"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "invites", ["event_id"], :name => "index_invites_on_event_id"
  add_index "invites", ["invited_user_id"], :name => "index_invites_on_invited_user_id"
  add_index "invites", ["inviter_user_id"], :name => "index_invites_on_inviter_user_id"

  create_table "likes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "likeable_id"
    t.string   "likeable_type", :limit => 50
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "likes", ["likeable_type", "likeable_id"], :name => "likeable_idx"
  add_index "likes", ["user_id"], :name => "index_likes_on_user_id"

  create_table "locations", :force => true do |t|
    t.integer  "promotion_id"
    t.string   "name"
    t.integer  "sequence"
    t.integer  "root_location_id"
    t.integer  "parent_location_id"
    t.integer  "depth"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "flags_1",            :limit => 8, :default => 0
  end

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.boolean  "viewed",                               :default => false
    t.text     "message"
    t.string   "key",                   :limit => 25
    t.string   "title",                 :limit => 100
    t.integer  "notificationable_id"
    t.string   "notificationable_type", :limit => 50
    t.integer  "from_user_id"
    t.integer  "hidden",                :limit => 1,   :default => 0
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
  end

  add_index "notifications", ["from_user_id"], :name => "index_notifications_on_from_user_id"
  add_index "notifications", ["notificationable_id", "notificationable_type"], :name => "notifications_index"
  add_index "notifications", ["user_id"], :name => "index_notifications_on_user_id"

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
    t.text     "color",          :limit => 255
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "posts", :force => true do |t|
    t.integer  "parent_post_id"
    t.integer  "root_post_id"
    t.integer  "user_id"
    t.integer  "depth",          :default => 0
    t.text     "content"
    t.integer  "postable_id"
    t.string   "postable_type"
    t.integer  "wallable_id"
    t.string   "wallable_type"
    t.boolean  "is_flagged",     :default => false
    t.boolean  "is_deleted",     :default => false
    t.text     "photo"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "posts", ["parent_post_id"], :name => "index_posts_on_parent_post_id"
  add_index "posts", ["postable_type", "postable_id"], :name => "postable_idx"
  add_index "posts", ["root_post_id"], :name => "index_posts_on_root_post_id"
  add_index "posts", ["user_id"], :name => "index_posts_on_user_id"
  add_index "posts", ["wallable_type", "wallable_id"], :name => "wallable_idx"

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "gender",         :limit => 1
    t.integer  "daily_goal"
    t.string   "first_name",     :limit => 100
    t.string   "last_name",      :limit => 100
    t.string   "phone",          :limit => 30
    t.string   "mobile_phone",   :limit => 11
    t.string   "line1",          :limit => 150
    t.string   "line2",          :limit => 150
    t.string   "city",           :limit => 150
    t.string   "state_province", :limit => 150
    t.string   "country",        :limit => 150
    t.string   "postal_code",    :limit => 150
    t.string   "time_zone"
    t.string   "group"
    t.string   "entity"
    t.date     "started_on"
    t.date     "registered_on"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.string   "image"
    t.integer  "flags_1",        :limit => 8,   :default => 0
  end

  create_table "profiles_udfs", :force => true do |t|
    t.integer "profile_id"
  end

  add_index "profiles_udfs", ["profile_id"], :name => "by_profile_id"

  create_table "promotions", :force => true do |t|
    t.integer  "organization_id"
    t.integer  "map_id"
    t.string   "name",                        :limit => 100
    t.string   "program_name",                :limit => 100
    t.string   "subdomain",                   :limit => 30
    t.string   "pilot_password",              :limit => 30
    t.string   "theme",                       :limit => 30
    t.string   "logo_url"
    t.integer  "max_participants"
    t.integer  "program_length"
    t.date     "launch_on"
    t.date     "starts_on"
    t.date     "registration_starts_on"
    t.date     "registration_ends_on"
    t.date     "late_registration_ends_on"
    t.boolean  "is_active",                                                                 :default => false
    t.boolean  "is_archived",                                                               :default => false
    t.boolean  "is_registration_frozen",                                                    :default => true
    t.integer  "participation_x",                                                           :default => 1
    t.integer  "participation_y",                                                           :default => 7
    t.integer  "minimum_minutes_low",                                                       :default => 30
    t.integer  "minimum_minutes_medium",                                                    :default => 45
    t.integer  "minimum_minutes_high",                                                      :default => 60
    t.integer  "minimum_steps_low",                                                         :default => 6000
    t.integer  "minimum_steps_medium",                                                      :default => 8000
    t.integer  "minimum_steps_high",                                                        :default => 10000
    t.integer  "default_goal",                                                              :default => 20
    t.string   "time_zone",                                                                 :default => "Eastern Time (US & Canada)"
    t.decimal  "multiplier",                                  :precision => 7, :scale => 5, :default => 1.0
    t.integer  "single_day_minute_limit",                                                   :default => 90
    t.integer  "single_day_step_limit",                                                     :default => 15000
    t.string   "location_labels",             :limit => 1000,                               :default => "Location"
    t.integer  "challenges_sent_points",                                                    :default => 1
    t.integer  "challenges_completed_points",                                               :default => 1
    t.integer  "max_challenges_sent",                                                       :default => 4
    t.integer  "max_challenges_completed",                                                  :default => 4
    t.text     "static_tiles"
    t.text     "dynamic_tiles"
    t.datetime "created_at",                                                                                                          :null => false
    t.datetime "updated_at",                                                                                                          :null => false
  end

  create_table "rel_entries_exercises_activities", :force => true do |t|
    t.integer  "entry_id"
    t.integer  "exercise_activity_id"
    t.integer  "value"
    t.date     "created_on"
    t.datetime "created_at"
    t.date     "updated_on"
    t.datetime "updated_at"
  end

  add_index "rel_entries_exercises_activities", ["entry_id"], :name => "by_entry_id"
  add_index "rel_entries_exercises_activities", ["exercise_activity_id"], :name => "by_exercise_activity_id"

  create_table "rel_evaluations_definitions_customs_prompts", :force => true do |t|
    t.integer  "evaluation_definition_id"
    t.integer  "custom_prompt_id"
    t.date     "created_on"
    t.datetime "created_at"
    t.date     "updated_on"
    t.datetime "updated_at"
  end

  add_index "rel_evaluations_definitions_customs_prompts", ["custom_prompt_id"], :name => "by_custom_prompt_id"
  add_index "rel_evaluations_definitions_customs_prompts", ["evaluation_definition_id", "custom_prompt_id"], :name => "rel_evaluations_definitions_customs_prompts_unique_index", :unique => true
  add_index "rel_evaluations_definitions_customs_prompts", ["evaluation_definition_id"], :name => "by_evaluation_definition_id"

  create_table "resellers", :force => true do |t|
    t.string   "name",          :limit => 100
    t.string   "contact_name",  :limit => 100
    t.string   "contact_email", :limit => 100
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  create_table "suggested_challenges", :force => true do |t|
    t.integer  "promotion_id"
    t.text     "description"
    t.integer  "user_id"
    t.integer  "status"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "name"
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

  create_table "timed_behaviors", :force => true do |t|
    t.integer  "behavior_id"
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
    t.string  "field_name"
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
    t.text     "tiles"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

end
