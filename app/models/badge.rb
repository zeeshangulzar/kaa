class Badge < ActiveRecord::Base
  Milestones = {"ORANGE"=>50,"GREEN"=>100,"BRONZE"=>250,"SILVER"=>500,"GOLD"=>750,"PLATINUM"=>1000,"DIAMOND"=>1500}
  Weekender = "WEEKENDER"
  WeekendWarrior = "WEEKEND_WARRIOR"

  belongs_to :user

  attr_privacy :badge_key, :earned_year, :sequence, :connections
  attr_privacy :user_id, :earned_date, :me 

  attr_accessible *column_names 

  # query returns what the milestones SHOULD BE
  def self.milestone_query(user_id,year)
    cases = Milestones.keys.sort{|x,y|Milestones[y]<=>Milestones[x]}.collect{|k| "when total_points >=#{Milestones[k]} then '#{k}'"}
    "
      select milestone,min(as_of) earned_on, if(badges.id is null, 'ADD', if(as_of=badges.earned_date,'OK','UPDATE')) to_do from (
        select case
        #{cases.join("\n")}
        else null
        end milestone, as_of from(
          select sum(moving_e.exercise_points + moving_e.challenge_points + moving_e.timed_behavior_points) total_points, e.recorded_on as_of 
          from entries e 
          left join entries moving_e on (moving_e.user_id = e.user_id and year(moving_e.recorded_on) = #{year.to_i} and moving_e.recorded_on <= e.recorded_on) 
          where e.user_id = #{user_id.to_i}
          and year(e.recorded_on) = #{year.to_i}
          group by e.recorded_on
        ) x
      )y 
      left join badges on badges.user_id = #{user_id.to_i} and earned_year = #{year.to_i} and badges.badge_key = y.milestone
      where milestone is not null 
      group by milestone;
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
