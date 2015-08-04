class CreateBehaviorsTable < ActiveRecord::Migration
  def change
    create_table :behaviors do |t|
      t.references :promotion
      t.string   :name
      t.text     :content
      t.text     :summary
      t.integer  :sequence, :default => 0
      t.timestamps
    end
  end
end
