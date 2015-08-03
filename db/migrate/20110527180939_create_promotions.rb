class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.references  :organization, :map
      t.string      :name, :program_name,         :limit => 100
      t.string      :subdomain, :pilot_password,  :theme, :limit => 30
      t.string      :logo_url
      t.integer     :max_participants, :program_length
      t.date        :launch_on, :starts_on, :registration_starts_on, :registration_ends_on, :late_registration_ends_on
      t.boolean     :is_active, :is_archived,     :default => false
      t.boolean     :is_registration_frozen,      :default => true
      t.integer     :participation_x,             :default => 1
      t.integer     :participation_y,             :default => 7
      t.integer     :minimum_minutes_low,         :default => 30
      t.integer     :minimum_minutes_medium,      :default => 45
      t.integer     :minimum_minutes_high,        :default => 60
      t.integer     :minimum_steps_low,           :default => 6000
      t.integer     :minimum_steps_medium,        :default => 8000
      t.integer     :minimum_steps_high,          :default => 10000
      t.integer     :default_goal,                :default => 20
      t.string      :time_zone,                   :default => "Eastern Time (US & Canada)"
      t.decimal     :multiplier,                  :precision => 7, :scale => 5, :default => 1
      t.integer     :single_day_minute_limit,     :default => 90
      t.integer     :single_day_step_limit,       :default => 15000
      t.string      :location_labels,             :limit => 1000, :default => 'Location'
      t.timestamps
    end
  end
end
