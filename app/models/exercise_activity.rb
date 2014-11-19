class Activity < ActiveRecord::Base
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :name, :public

  many_to_many :with => :entry, :primary => :entry, :fields => [[:value, :integer]]

  attr_accessible :name, :summary

end