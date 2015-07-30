class CreateGiftsTable < ActiveRecord::Migration
  def change
    create_table :gifts do |t|
      t.references :promotion
      t.string   :name
      t.text     :content
      t.string   :type_of_prompt
      t.integer  :cap_value
      t.string   :cap_message,    :limit => 200
      t.string   :regex_validation, :limit => 20
      t.text     :options
      t.text     :summary
      t.integer  :sequence
      t.timestamps
    end
  end
end
