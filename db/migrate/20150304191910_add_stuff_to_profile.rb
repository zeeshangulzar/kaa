class AddStuffToProfile < ActiveRecord::Migration
  def up
    add_column :profiles, :employee_group, :string
    add_column :profiles, :shirt_size, :string
    add_column :profiles, :is_reward_participant, :boolean

    change_column :posters, :content, :text
  end
  def down
    remove_column :profiles, :employee_group
    remove_column :profiles, :shirt_size
    remove_column :profiles, :is_reward_participant

    change_column :posters, :content, :string
  end
end
