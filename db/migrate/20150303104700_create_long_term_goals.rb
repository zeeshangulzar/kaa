class CreateLongTermGoals < ActiveRecord::Migration
  def change
    create_table :long_term_goals do |t|
      t.integer     :user_id
      t.string      :title
      t.text        :content
      t.string      :image
      t.boolean     :completed
      t.date        :completed_on
      t.timestamps
    end
  end
end