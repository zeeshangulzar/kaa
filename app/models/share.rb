# Like active record class for keeping track of likes that users have
class Share < ApplicationModel
  belongs_to :shareable, :polymorphic => true
  belongs_to :user, :in_json => true

  attr_privacy_path_to_user :user
  attr_privacy :shareable, :shareable_type, :shareable_id, :via, :me

  scope :typed, lambda{|shareable_type| where(:shareable_type => shareable_type)}

  # Overrides likeable built by polymorphic association in case likeable is not an ActiveRecord
  def shareable
    unless HesShareable::ActsAsShareable.non_active_record_shareables.collect(&:to_s).include?(self.shareable_type)
      Rails.logger.info "\n\nNonActiveRecordShareables: #{HesShareable::ActsAsShareable.non_active_record_shareables.collect(&:to_s).inspect}\n\n"
      super
    else
      HesShareable::ActsAsShareable.non_active_record_shareables.detect{|x| x.to_s == self.shareable_type}.find(self.shareable_id)
    end
  end
  
  after_create :do_badges
  after_destroy :do_badges

  def do_badges
    Badge.do_chef(self)
    Badge.do_head_chef(self)
    Badge.do_tipster(self)
    Badge.do_uber_tipster(self)
  end

end
