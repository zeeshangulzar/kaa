class Challenge < ApplicationModel
  self.inheritance_column = 'column_that_is_not_type'
  attr_privacy :promotion_id, :name, :description, :type, :location_id, :any_user
  attr_privacy_no_path_to_user
  attr_accessible *column_names
  
  belongs_to :promotion
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :location, :in_json => true

  has_many :challenges_sent, :class_name => "ChallengeSent"
  has_many :challenges_received, :class_name => "ChallengeReceived"
  
  TYPE = {
    :peer     => 'peer',
    :regional => 'regional'
  }

  TYPE.each_pair do |key, value|
    self.send(:scope, key, where(:type => value))
  end

  TYPE.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.type == value })
  end

end