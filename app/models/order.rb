class Order < ActiveRecord::Base
  attr_accessible :last_4, :total_amount, :payment_type, :item_key

  belongs_to :user

  def as_json(options={})
    super(options.merge({:except => [:last_4]}))
  end
end
