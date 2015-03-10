# Like active record class for keeping track of likes that users have
class Rating < ApplicationModel
  belongs_to :rateable, :polymorphic => true
  belongs_to :user, :in_json => true

  attr_privacy_path_to_user :user
  attr_privacy :rateable, :rateable_type, :rateable_id, :score, :me

  scope :typed, lambda{|rateable_type| where(:rateable_type => rateable_type)}

  # Overrides likeable built by polymorphic association in case likeable is not an ActiveRecord
  def rateable
    unless HesRateable::ActsAsRateable.non_active_record_rateables.collect(&:to_s).include?(self.rateable_type)
      Rails.logger.info "\n\nNonActiveRecordRateables: #{HesRateable::ActsAsRateable.non_active_record_rateables.collect(&:to_s).inspect}\n\n"
      super
    else
      HesRateable::ActsAsRateable.non_active_record_rateables.detect{|x| x.to_s == self.rateable_type}.find(self.rateable_id)
    end
  end
  
  after_create :do_badges
  after_destroy :do_badges

  def do_badges
    # critic badges or whatever..
  end

end
