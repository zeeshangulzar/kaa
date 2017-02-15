class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :user, null: false
      t.text       :content, limit: 1000
      t.timestamps
    end
  end
end
