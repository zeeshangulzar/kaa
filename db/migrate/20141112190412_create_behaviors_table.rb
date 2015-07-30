class CreateBehaviorsTable < ActiveRecord::Migration
  def change
    create_table :behaviors do |t|
      t.references :promotion
      t.string   :name
      t.text     :content
      t.text     :summary
    
      t.timestamps
    end
  end
end
