class TeamMember < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :id, :team_id, :user_id, :user, :user
  
  # Associations
  belongs_to :user
  belongs_to :team

  # NOTE: this is not cognizant of whether the team is official, the competition is active, freezes_on_date, etc.
  # presently doing those types of checks on user.current_team()
  def update_points
    sql = "
      UPDATE team_members
      JOIN (
        SELECT
          SUM(entries.timed_behavior_points + entries.exercise_points + entries.challenge_points) AS total_points, user_id
        FROM entries
        WHERE
          user_id = #{self.user_id}
          AND entries.recorded_on BETWEEN '#{self.team.competition.competition_starts_on}' AND '#{self.team.competition.competition_ends_on}'
        ) stats on stats.user_id = team_members.user_id
      SET
        team_members.total_points = stats.total_points
    "
    self.connection.execute(sql)
  end

end
