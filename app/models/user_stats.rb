class UserStats < ApplicationModel
 
=begin
#
# STATS METHODS
#

  def self.stats(user_ids,year)
    user_ids = [user_ids] unless user_ids.is_a?(Array)
    user = self
    sql = "
      SELECT
      entries.user_id AS user_id,
      SUM(exercise_points) AS total_exercise_points,
      SUM(challenge_points) AS total_challenge_points,
      SUM(timed_behavior_points) AS total_timed_behavior_points,
      SUM(exercise_steps) AS total_exercise_steps,
      SUM(exercise_minutes) AS total_exercise_minutes,
      SUM(exercise_points) + SUM(challenge_points) + SUM(timed_behavior_points) AS total_points,
      AVG(exercise_minutes) AS average_exercise_minutes,
      AVG(exercise_steps) AS average_exercise_steps
      FROM
      entries
      WHERE
      user_id in (#{user_ids.join(',')})
      AND YEAR(recorded_on) = #{year}
      GROUP BY user_id
    "
    # turns [1,2,3] into {1=>{},2=>{},3=>{}} where each sub-hash is missing data (to be replaced by query)
    keys = ['total_exercise_points','total_challenge_points','total_timed_behavior_points','total_exercise_steps','total_exercise_minutes','total_points','average_exercise_minutes','average_exercise_steps']
    zeroes = Hash[*keys.collect{|k|[k,0]}.flatten]
    user_stats = Hash[*user_ids.collect{|id|[id,zeroes]}.flatten]
    self.connection.select_all(sql).each do |row|
      user_stats[row['user_id'].to_i] = row
    end
    return user_stats
  end

  def stats(year = self.promotion.current_date.year)
    unless @stats
      arr =  self.class.stats([self.id],year)
      @stats = arr[self.id]
    end
    @stats
  end

  def stats=(hash)
    @stats=hash
  end
=end

end
