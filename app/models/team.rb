class Team < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :name, :motto, :members, :any_user

  has_many :team_members
  has_many :members, :through => :team_members, :source => :user
  has_many :team_invites

  validates_presence_of :name

  validates_uniqueness_of :name, :scope => :competition_id

  def leader
    unless self.team_members.where(:is_leader => 1).empty?
      return self.team_members.where(:is_leader => 1).first.user
    end
    return nil
  end

  def disband
    team.members.each do |member|
      member.notifications.find(:all, :conditions => ["message like ?", "%join a #{Team::Title}: #{team.name}</a>."]).each{|x| x.destroy}
      member.add_notification("#{team.name} has been disbanded.  You can join or start a different team.")
      reset_user_app_menu(member) #redraw menu so that user can access team links
    end
  end

end
