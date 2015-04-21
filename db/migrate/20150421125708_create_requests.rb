class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.references    :user
      t.string        :uri
      t.string        :ip
      t.string        :info
      t.timestamps
    end
  end
end
