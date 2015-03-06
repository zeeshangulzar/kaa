class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders do |t|
      t.references    :user
      t.string        :item_key,                :limit => 100
      t.string        :payment_type,            :limit => 1
      t.string        :last_4,                  :limit => 4
      t.string        :reference,               :limit => 255
      t.string        :additional_1
      t.string        :additional_2
      t.string        :additional_3
      t.string        :additional_4
      t.string        :additional_5
      t.decimal       :total_amount,            :precision=>7, :scale=>2
      t.boolean       :is_shippable
      t.date          :fulfilled_on
      t.string        :line_1
      t.string        :line_2
      t.string        :city
      t.string        :state
      t.string        :postal_code
 
      t.timestamps
    end
  end

  def self.down
    drop_table :orders
  end
end
