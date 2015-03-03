class PersonalActionPlan < ApplicationModel

  attr_privacy_path_to_user :user
  attr_privacy :id, :user_id, :user, :long_term_goal_id, :goal, :activity, :how_much, :when, :how_many, :confidence_level, :difficulties, :support, :reward, :review_date, :review_with, :signature, :created_at, :updated_at, :me
  attr_accessible *column_names
  
  belongs_to :long_term_goal
  belongs_to :user

end