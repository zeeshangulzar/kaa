class Forum < ApplicationModel

  attr_privacy_no_path_to_user
  attr_privacy :id, :location_id, :location, :name, :summary, :content, :image, :sequence, :any_user
  attr_accessible *column_names

  belongs_to :location

  has_wall

  mount_uploader :image, ForumImageUploader

  def as_json(options = {})
    options = options.merge({:methods => ["post_count"]})
    super
  end

  def post_count
    return self.posts.count
  end

end