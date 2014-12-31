# Comment migration
class CreateEvents < ActiveRecord::Migration
  # Comment migration
  def change
    create_table :events do |t|
      t.references  :user
      t.string      :event_type, :limit => 1
      t.string      :place, :limit => 200
      t.boolean     :can_others_invite, :default => false
      t.datetime    :start
      t.datetime    :end
      t.boolean     :all_day, :default => false
      t.string      :name, :limit => 200
      t.text        :description
      t.string      :privacy, :limit => 1
      t.string      :photo
      t.integer     :location_id, :default => nil
      t.timestamps

    end

    add_index :events, :user_id
  end
end
