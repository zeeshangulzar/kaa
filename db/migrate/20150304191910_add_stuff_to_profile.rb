class AddStuffToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :employee_group, :string
    add_column :profiles, :shirt_size, :string
    add_column :profiles, :ethnicity, :string
    add_column :profiles, :age, :integer
    add_column :profiles, :is_reward_participant, :boolean

    change_column :posters, :content, :text
  end
end
