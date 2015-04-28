class TeamMember < ApplicationModel
  attr_accessible *column_names
  attr_privacy_path_to_user :user
  attr_privacy :id, :team_id, :user_id, :user, :total_points, :total_exercise_points, :total_timed_behavior_points, :total_challenge_points, :connections
  
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
          user_id
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
        team_members.total_points = stats.total_points,
        team_members.total_exercise_points = stats.total_exercise_points,
        team_members.total_timed_behavior_points = stats.total_timed_behavior_points,
        team_members.total_challenge_points = stats.total_challenge_points
    "
    self.connection.execute(sql)
  end

end
