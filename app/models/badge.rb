class Badge < ActiveRecord::Base
  Milestones = {"ORANGE"=>50,"GREEN"=>100,"BRONZE"=>250,"SILVER"=>500,"GOLD"=>750,"PLATINUM"=>1000,"DIAMOND"=>1500}
  Weekender = "WEEKENDER"
  WeekendWarrior = "WEEKEND_WARRIOR"

  belongs_to :user

  attr_privacy :badge_key, :earned_year, :sequence, :connections
  attr_privacy :user_id, :earned_date, :me 

  # query returns what the milestones SHOULD BE
  def self.milestone_query(user_id,year)
    cases = Milestones.keys.sort{|x,y|Milestones[y]<=>Milestones[x]}.collect{|k| "when total_points >=#{Milestones[k]} then '#{k}'"}
    "
      select milestone,min(as_of) earned_on, if(badges.id is null, 'ADD', if(as_of=badges.earned_date,'OK','UPDATE')) to_do from (
        select case
        #{cases.join("\n")}
        else null
        end milestone, as_of from(
          select sum(moving_e.daily_points + moving_e.challenge_points + moving_e.timed_behavior_points) total_points, e.recorded_on as_of 
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
end
