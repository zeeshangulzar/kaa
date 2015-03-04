class CreatePersonalActionPlans < ActiveRecord::Migration
  def change
    create_table :personal_action_plans do |t|
      t.integer     :user_id
      t.integer     :long_term_goal_id
      t.text        :goal
      t.string      :activity
      t.string      :how_much
      t.string      :when
      t.string      :how_many
      t.string      :confidence_level
      t.string      :difficulties
      t.string      :support
      t.string      :reward
      t.date        :review_date
      t.string      :review_with
      t.string      :signature
      t.timestamps
    end
  end
end