class TeamMember < ApplicationModel
  attr_accessible *column_names
  attr_privacy_path_to_user :user
  attr_privacy :id, :team_id, :user_id, :user, :any_user
  attr_privacy :total_points, :total_exercise_points, :total_timed_behavior_points, :total_challenge_points, :connections
  
  # Associations
  belongs_to :user
  belongs_to :team

  after_create :delete_team_invites
  after_create :delete_old_team_members
  after_create :update_points

  after_create :update_team
  after_save :update_team
  after_destroy :update_team

  # NOTE: this is not cognizant of whether the team is official, the competition is active, freezes_on_date, etc.
  # presently doing those types of checks on user.current_team()
  def update_points
    sql = "
      UPDATE team_members
      JOIN (
        SELECT
          user_id,
          SUM(entries.timed_behavior_points + entries.exercise_points + entries.challenge_points) AS total_points,
          SUM(entries.exercise_points) AS total_exercise_points,
          SUM(entries.timed_behavior_points) AS total_timed_behavior_points,
          SUM(entries.challenge_points) AS total_challenge_points
        FROM entries
        WHERE
          user_id = #{self.user_id}
          AND entries.recorded_on BETWEEN '#{self.team.competition.competition_starts_on}' AND '#{self.team.competition.competition_ends_on}'
        ) stats on stats.user_id = team_members.user_id
      SET
        team_members.total_points = COALESCE(stats.total_points, 0),
        team_members.total_exercise_points = COALESCE(stats.total_exercise_points, 0),
        team_members.total_timed_behavior_points = COALESCE(stats.total_timed_behavior_points, 0),
        team_members.total_challenge_points = COALESCE(stats.total_challenge_points, 0)
    "
    self.connection.execute(sql)
  end

  def update_team
    self.team.handle_status()
  end

  def delete_team_invites
    self.user.team_invites.each{|invite|
      invite.destroy
    }
  end

  def delete_old_team_members
    team_members = TeamMember.where("user_id = ? AND team_id <> ? AND competition_id = ?", self.user.id, self.team.id, self.team.competition.id)
    team_members.each{|team_member|
      team_member.destroy
    }
  end

end
