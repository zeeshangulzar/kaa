class UserBadge < ApplicationModel
  attr_accessible *column_names
  attr_privacy :user_id, :badge_id, :badge, :earned_year, :earned_date, :created_at, :updated_at, :any_user
  
  belongs_to :user
  belongs_to :badge

  after_create :send_notification

  acts_as_notifier

  def send_notification
    appendages = [
      'Feels good, doesn\'t it?',
      'Nice.',
      'Way to Go.',
      'KP it up.',
      'Well done.',
      'Super.'
    ]
    if self.badge.badge_type == Badge::TYPE[:milestones]
      name = 'Milestone'
      appendage = appendages.slice(0, 2).sample
    else
      name = 'Achievement'
      appendages.unshift
      appendage = appendages.sample
    end
    msg = "You've earned the <a href='/#/summary?view=trophy_case'>" + self.badge.name + " #{name}</a>. " + appendage
    self.notify(self.user, name + " Earned", msg, :from => self.user, :key => "user_badge_#{self.id}")
  end

end
