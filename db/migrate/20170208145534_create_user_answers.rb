class CreateUserAnswers < ActiveRecord::Migration
  def change
    create_table :user_answers do |t|
      t.references :user, :destination
      t.string :answer
      t.boolean :is_correct
      t.timestamps
    end
  end
end
