# Comment migration
class CreateInvites < ActiveRecord::Migration
  # Comment migration
  def change
    create_table :invites do |t|
      t.integer     :event_id
      t.integer     :invited_user_id
      t.integer     :inviter_user_id
      t.integer     :status
      t.timestamps

    end
    
    add_index :invites, :event_id
    add_index :invites, :inviter_user_id
    add_index :invites, :invited_user_id

  end
end
