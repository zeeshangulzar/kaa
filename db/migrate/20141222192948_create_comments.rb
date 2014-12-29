# Comment migration
class CreateComments < ActiveRecord::Migration
  # Comment migration
  def change
    create_table :comments do |t|

      t.references   :user
      t.integer     :commentable_id
      t.string      :commentable_type,                      :limit => 50
      t.string      :content,                               :limit => 420
      t.boolean     :is_flagged, :is_deleted,               :default => false
      t.datetime    :last_modified_at
      t.timestamps

    end

    add_index :comments, :user_id
    add_index :comments, [:commentable_type, :commentable_id], :name => :commentable_idx
  end
end
