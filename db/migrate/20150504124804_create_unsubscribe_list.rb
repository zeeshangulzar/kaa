class CreateUnsubscribeList < ActiveRecord::Migration
  def change
    create_table :unsubscribe_list do |t|
      t.integer     :promotion_id
      t.integer     :user_id
      t.string      :email
      t.timestamps
    end
  end
end
