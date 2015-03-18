class LongTermGoal < ApplicationModel

  attr_privacy_path_to_user :user
  attr_privacy :id, :user_id, :user, :title, :content, :image, :completed, :completed_on, :created_at, :updated_at, :me
  attr_accessible *column_names

  mount_uploader :image, LongTermGoalImageUploader

  belongs_to :user
  
  has_one :personal_action_plan
  accepts_nested_attributes_for :personal_action_plan

  scope :completed, where(:completed => true).order("completed_on ASC")

  after_commit :do_badges, :on => [:create, :update]

  def do_badges
    Badge.do_willpower(self)
    Badge.do_transformer(self)
  end

end