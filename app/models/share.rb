# Like active record class for keeping track of likes that users have
class Share < ApplicationModel
  belongs_to :shareable, :polymorphic => true
  belongs_to :user

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
end
