class SuggestedChallenge < ApplicationModel
  attr_privacy :promotion_id, :description, :user_id, :status, :name, :any_user
  attr_privacy_path_to_user :user
  attr_accessible *column_names
  
  belongs_to :promotion
  belongs_to :user

  STATUS = {
    :unseen    => 0,
    :pending   => 1,
    :accepted  => 2,
    :declined  => 3
  }

  before_create :set_defaults

  def set_defaults
    self.status ||= STATUS[:unseen]
  end

end