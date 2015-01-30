class Badge < ActiveRecord::Base

  attr_privacy_no_path_to_user
  attr_accessible *column_names
  attr_privacy :promotion_id, :name, :description, :completion_message, :image, :badge_type, :point_goal, :sequence, :any_user

  validates_presence_of :badge_type, :promotion_id, :name

  belongs_to :promotion

  mount_uploader :image, BadgeImageUploader

  TYPE = {
    :milestones   => 'milestone',
    :achievements => 'achievement'
  }

  TYPE.each_pair do |key, value|
    self.send(:scope, key, where(:badge_type => value))
  end

  # query returns what the milestones SHOULD BE
  def self.milestone_query(user_id,year)
    milestones = Promotion.find(User.find(user_id).promotion_id).milestone_goals
    return nil if milestones.empty?
    cases = milestones.keys.sort{|x,y|milestones[y]<=>milestones[x]}.collect{|k| "when total_points >=#{milestones[k]} then #{k}"}
    "
SELECT
milestone, MIN(as_of) earned_on, IF(user_badges.id is null, 'ADD', IF(as_of=user_badges.earned_date,'OK','UPDATE')) to_do
FROM (
SELECT
  CASE
    #{cases.join("\n")}
    ELSE null
  END milestone, as_of
  FROM (
    SELECT
    @runtot := (@runtot + z.total_points) AS total_points, z.as_of
    FROM (
      SELECT
      @runtot := 0, SUM(e.exercise_points + e.challenge_points + e.timed_behavior_points) total_points, e.recorded_on as_of
      FROM
        entries e
      WHERE
        e.user_id = #{user_id.to_i}
        AND year(e.recorded_on) = #{year.to_i}
      GROUP BY e.recorded_on
    ) z
  ) x
)y 
LEFT JOIN user_badges on user_badges.user_id = #{user_id.to_i} and earned_year = #{year.to_i} and user_badges.badge_id = y.milestone
WHERE milestone is not null
GROUP BY milestone;
  "
  end

  def self.weekend_query(user_id,year)
      sql = "
        select z.badge_key, week, recorded_on, z.sequence, badges.id badge_id from (
          select '#{Badge::WeekendWarrior}' badge_key, week, recorded_on, @sequence:=@sequence+1 sequence from(
              select
              @week := x.week week,
              if(@week >= @next_possible, 'Y', 'N') award,
              @next_possible:=if(@week >= @next_possible, @week+5,@next_possible) next_possible,
              x.recorded_on
              from(
                select 
                  week(entries.recorded_on,1) week,
                  min(entries.recorded_on) recorded_on, 
                  count(distinct week(moving_e.recorded_on,1)) consecutive
                from entries
                left join entries moving_e on moving_e.user_id = entries.user_id 
                                              and year(moving_e.recorded_on) = year(entries.recorded_on) 
                                              and weekday(moving_e.recorded_on) in (5,6) and week(moving_e.recorded_on,1) 
                                              between week(entries.recorded_on,1) - 4  and week(entries.recorded_on,1)
                where entries.user_id = #{user_id}
                and weekday(entries.recorded_on) in (5,6) 
                and year(entries.recorded_on) = #{year}
                group by week(entries.recorded_on,1)
                having count(distinct week(moving_e.recorded_on,1)) = 5
              ) x
              left join (select @next_possible := 5, @week := 1) test on 1=1
          )y 
          left join (select @sequence :=-1) test on 1=1
          where y.award = 'Y'
          UNION
          select '#{Badge::Weekender}',week(min(entries.recorded_on),1),min(entries.recorded_on),0
          from entries
          where user_id = #{user_id} and year(recorded_on) = #{year} and weekday(entries.recorded_on) in (5,6) 
        ) z 
        left join badges on badges.user_id = #{user_id} and earned_year = #{year} and badges.badge_key = z.badge_key and badges.sequence = z.sequence"
  end

  def self.possible(for_promotion,year)
    # ignoring for_promotion and year for now
    # eventually we'll want to do something with those...
    Milestones.keys.concat([Weekender,WeekendWarrior])
  end
end
