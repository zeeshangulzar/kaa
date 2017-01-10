class Destination < ApplicationModel
  attr_privacy :id, :name, :icon1, :icon2, :content, :blurb, :question, :answers, :sequence, :map_id, :any_user
  attr_privacy_no_path_to_user
  attr_accessible :map_id, :name, :icon1, :icon2, :content, :blurb, :question, :answers, :correct_answer, :status, :sequence, :created_at, :updated_at

  belongs_to :map

  mount_uploader :icon1, DestinationIcon1Uploader
  mount_uploader :icon2, DestinationIcon2Uploader

  has_photos # TODO: temporary?

  # TODO: do these make sense?
  STATUS = {
    :active   => 'active',
    :deleted  => 'deleted'
  }
  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end
  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  def destroy
    # TODO: we want to do a soft delete, so figure out what this should do...
    self.status = STATUS[:deleted]
    self.save!
  end
  
end