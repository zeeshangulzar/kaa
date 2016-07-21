class Route < ApplicationModel
  attr_privacy :id, :name, :travel_type, :status, :points, :public
  attr_privacy_no_path_to_user
  attr_accessible *column_names

  belongs_to :map

  # TODO: do these make sense?
  STATUS = {
    :inactive => 0,
    :active   => 1,
    :deleted  => 2
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

  def as_json(options = {})
    json = super(options)
    json['points'] = JSON.parse(self.points) # TODO: make this faster and more efficient
    json
  end
  
end