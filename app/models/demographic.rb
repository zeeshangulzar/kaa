class Demographic < ApplicationModel
  # attrs
  attr_accessible :user_id, :gender, :ethnicity, :age
  attr_privacy :user_id, :gender, :ethnicity, :age, :public
  attr_privacy_path_to_user :user

  # relationships
  belongs_to :user

  def to_json(options={})
    options[:except] ||= [:age,:ethnicity,:gender]
    super(options)
  end

end
