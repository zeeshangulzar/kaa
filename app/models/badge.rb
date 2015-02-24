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

  def self.possible(for_promotion,year)
    # ignoring for_promotion and year for now
    # eventually we'll want to do something with those...
    Milestones.keys.concat([Weekender,WeekendWarrior])
  end

  # handles inserts, updates & deletes
  def self.process_for_user(user_id, earned_date, options = {})
    u = User.find(user_id) rescue nil
    return if !u

    options[:create]  ||= [] # [badge_id, earned_date]
    options[:update]  ||= [] # [badge_id, earned_date]
    options[:destroy] ||= [] # badge_id

    now = u.promotion.current_time.to_s(:db)

    connection.execute("DELETE FROM user_badges WHERE user_id = #{user_id} AND earned_year = #{earned_date.year} AND badge_id IN (#{options[:destroy].join(",")})") unless options[:destroy].empty?

    options[:create].each_with_index{|create,index|
      # TODO: do badge notifications here
      options[:create][index] = [user_id, options[:create][index][0], options[:create][index][1].year, "'#{options[:create][index][1]}'", "'#{now}'", "'#{now}'"].join(',')
      options[:create][index] = "(#{options[:create][index]})"
    }

    connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES #{options[:create].join(",\n")}") unless options[:create].empty?

    options[:update].each{|update|
      connection.execute("UPDATE user_badges SET earned_date = '#{update[1]}', updated_at = '#{now}' WHERE user_id = #{user_id} AND earned_year = #{update[1].year} AND badge_id = #{update[0]}")
    }
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

  def self.do_milestones(entry)
    query = self.milestone_query(entry.user_id,entry.recorded_on.year)
    return true unless query
    rows = connection.uncached{ connection.select_all(query) }
    inserts = []
    updates = []
    rows.each do |row|
      if row['to_do'] == 'ADD'
        inserts << [row['milestone'], row['earned_on']]
      elsif row['to_do'] == 'UPDATE'
        updates << [row['milestone'], row['earned_on']]
      end
    end
    deletes = (entry.user.promotion.milestone_goals.keys - rows.collect{|row|row['milestone']}).collect{|x|x}
    self.process_for_user(entry.user_id, entry.recorded_on, {:create => inserts, :update => updates, :destroy => deletes})
    return true
  end

  def self.do_goal_getter(entry)
    goal_getter_badge = entry.user.promotion.badges.where(:name => "Goal Getter").first rescue nil
    return true if !goal_getter_badge
    sql = "
      SELECT
        week_number,
        IF(SUM(daily_goal_met) = 5, 1, 0) AS weekly_goal_met,
        recorded_on
      FROM (
        SELECT
        WEEK(e.recorded_on, 3) AS week_number,
        e.recorded_on,
        IF(
          -- entry's minutes is greater than the goal minutes of the entry, fall back on profile
          IF(e.exercise_minutes > COALESCE(e.goal_minutes, profiles.goal_minutes, 0), 1, 0)
          OR
          -- entry's steps is greater than the goal steps of the entry, fall back on profile
          IF(e.exercise_steps > COALESCE(e.goal_steps, profiles.goal_steps, 0), 1, 0)
        , 1, 0) AS daily_goal_met
        FROM entries e
        JOIN profiles ON profiles.user_id = #{entry.user_id}
        WHERE
        e.user_id = #{entry.user_id}
        AND YEAR(e.recorded_on) = #{entry.recorded_on.year}
        AND WEEKDAY(e.recorded_on) NOT IN (5,6)
        AND e.recorded_on < '#{entry.user.promotion.current_date}'
      ) week2
      GROUP BY week_number
    "
    rows = connection.select_all(sql)
    last_goal_getter_week = nil
    last_row = nil
    earned = []
    rows.each{|row|
      if last_row && (row['week_number'] - last_row['week_number'] == 1) && row['weekly_goal_met'] > 0 && last_row['weekly_goal_met'] > 0
        if last_goal_getter_week && last_goal_getter_week['week_number'] == last_row['week_number']
          # skip
        else
          row['earned_date'] = row['recorded_on'].end_of_week - 2.days # friday of the recorded_on week (the date you earned this badge [gotta get down on friday])
          row['action'] = 'CREATE'
          last_goal_getter_week = row
          earned.push(row)
        end
      end
      last_row = row
    }
    # TODO: insert, update, and remove goal getter badge
    sql = "
      SELECT
        id, earned_date, IF(earned_date IN ('#{earned.collect{|x|x['earned_date']}.join("','")}'), 'KEEP', 'DESTROY') AS action
      FROM user_badges
      WHERE
        user_id = #{entry.user.id}
        AND badge_id = #{goal_getter_badge.id}
    "
    rows = connection.select_all(sql)

    records = (rows + earned.select{|y| !rows.collect{|x|x['earned_date']}.include?(y['earned_date'])})
    
    process = {
      :create  => records.select{|x|x['action'] == 'CREATE'}.collect{|x| {:badge_id => goal_getter_badge.id, :earned_date => x['earned_date']} },
      :destroy => records.select{|x|x['action'] == 'DESTROY'}.collect{|x| x['id'] }
    }

    now = entry.user.promotion.current_time.to_s(:db)

    connection.execute("DELETE FROM user_badges WHERE user_id = #{entry.user.id} AND id IN (#{process[:destroy].join(",")})") unless process[:destroy].empty?

    process[:create].each_with_index{|create,index|
      # TODO: notification
      process[:create][index] = [entry.user.id, process[:create][index][:badge_id], process[:create][index][:earned_date].year, "'#{process[:create][index][:earned_date]}'", "'#{now}'", "'#{now}'"].join(',')
      process[:create][index] = "(#{process[:create][index]})"
    }

    connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES #{process[:create].join(",\n")}") unless process[:create].empty?

    return true

  end

  def self.do_enthusiast(post)
    return unless post.depth == 0 && post.wallable.id == post.user.promotion.id
    enthusiast_badge = post.user.promotion.badges.where(:name => "Enthusiast").first rescue nil
    return if !enthusiast_badge
    num = post.user.posts.where(:wallable_type => 'Promotion', :wallable_id => post.user.promotion.id, :depth => 0).where("created_at BETWEEN '#{post.created_at.beginning_of_week.to_time.to_s(:db)}' AND '#{post.created_at.end_of_week.to_time.to_s(:db)}'").size
    if num > 2 && post.user.badges_earned.where(:earned_year => post.created_at.year, :badge_id => enthusiast_badge.id).size < 1
      # TODO: notification and possibly destroy?
      now = post.user.promotion.current_time.to_s(:db)
      connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES (#{post.user.id}, #{enthusiast_badge.id}, #{post.created_at.year}, '#{post.created_at.to_date.to_s(:db)}', '#{now}', '#{now}')")
    end
    return true
  end

  def self.do_sidekick(friendship)
    sidekick_badge = friendship.friender.promotion.badges.where(:name => "Sidekick").first rescue nil
    return if !sidekick_badge
    now = friendship.friender.promotion.current_time.to_s(:db)
    # friendee...
    u = friendship.friendee
    if friendship.friendee && friendship.friendee.friends.size > 9 && friendship.friendee.badges_earned.where(:earned_year => friendship.updated_at.year, :badge_id => sidekick_badge.id).size < 1
      # TODO: notification
      connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES (#{u.id}, #{sidekick_badge.id}, #{friendship.updated_at.year}, '#{friendship.updated_at.to_date.to_s(:db)}', '#{now}', '#{now}')")
    else
      connection.execute("DELETE FROM user_badges WHERE user_id = #{u.id} AND earned_year = #{friendship.updated_at.year} AND badge_id = #{sidekick_badge.id}")
    end
    # friender...
    u = friendship.friender
    if friendship.friender && friendship.friender.friends.size > 9 && friendship.friender.badges_earned.where(:earned_year => friendship.updated_at.year, :badge_id => sidekick_badge.id).size < 1
      # TODO: notification
      connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES (#{u.id}, #{sidekick_badge.id}, #{friendship.updated_at.year}, '#{friendship.updated_at.to_date.to_s(:db)}', '#{now}', '#{now}')")
    else
      # remove sidekick badge
      connection.execute("DELETE FROM user_badges WHERE user_id = #{u.id} AND earned_year = #{friendship.updated_at.year} AND badge_id = #{sidekick_badge.id}")
    end
  end

  def do_rookie(challenge_received)
    # TODO: notification and possibly destroy?
    rookie_badge = challenge_received.user.promotion.badges.where(:name => "Rookie").first rescue nil
    return if !rookie_badge
    u = challenge_received.user
    completed = u.challenges_received.completed.size
    rookie = u.badges_earned.where(:badges=>{:name=>"Rookie"},:earned_year => u.promotion.current_date).size
    if rookie < 1 && completed > 0
      u.badges_earned.create(:badge_id => rookie_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
    end
  end

  def do_mvp(challenge_received)
    # TODO: notification and possibly destroy?
    mvp_badge = challenge_received.user.promotion.badges.where(:name => "MVP").first rescue nil
    return if !mvp_badge
    u = challenge_received.user
    completed = u.challenges_received.completed.size
    mvp = u.badges_earned.where(:badges=>{:name=>"MVP"},:earned_year => u.promotion.current_date).size
    if mvp < 1 && completed > 9
      u.badges_earned.create(:badge_id => mvp_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
    end
  end

  def do_applause(like)
    # TODO: notification and possibly destroy?
    applause_badge = like.user.promotion.badges.where(:name => "Applause").first rescue nil
    return if !applause_badge
    likes = like.likeable.likes.size
    u = like.likeable.user
    applause = u.badges_earned.where(:badges=>{:name=>"Applause"},:earned_year => u.promotion.current_date.year).size
    if applause < 1 && likes > 9
      u.badges_earned.create(:badge_id => applause_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
    end
  end

  def do_high_five(like)
    # TODO: notification and possibly destroy?
    high_five_badge = like.user.promotion.badges.where(:name => "Applause").first rescue nil
    return if !high_five_badge
    u = like.user
    likes = u.likes.where(:likeable_type => "Post").where("YEAR(created_at) = #{u.promotion.current_date.year}").size
    high_five = u.badges_earned.where(:badges=>{:name=>"High Five"},:earned_year => u.promotion.current_date.year).size
    if high_five < 1 && likes > 9
      u.badges_earned.create(:badge_id => high_five_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
    end
  end

  def do_coach(challenge_sent)
    # TODO: notification and possibly destroy?
    coach_badge = challenge_sent.user.promotion.badges.where(:name => "Coach").first rescue nil
    return if !coach_badge
    u = challenge_sent.user
    challenges_sent = u.challenges_sent.where("YEAR(created_at) = #{u.promotion.current_date.year}").size
    coach = u.badges_earned.where(:badges=>{:name=>"Coach"},:earned_year => u.promotion.current_date.year).size
    if coach < 1 && challenges_sent > 9
      u.badges_earned.create(:badge_id => coach_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
    end
  end

  def do_all_star(success_story)
    # TODO: notification and possibly destroy?
    all_star_badge = success_story.user.promotion.badges.where(:name => "All Star").first rescue nil
    return if !all_star_badge
    u = success_story.user
    all_star = u.badges_earned.where(:badges=>{:name=>"All Star"},:earned_year => u.promotion.current_date.year).size
    if all_star < 1
      u.badges_earned.create(:badge_id => all_star_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
    end
  end

  def self.do_weekender(entry)
    weekender_badge = entry.user.promotion.badges.where(:name => "Weekender").first rescue nil
    return if !weekender_badge
    u = entry.user

    # the query below may help you diagnose problems with weekend badges -- look for 5 consecutive weeks in the results
    #   select week(recorded_on,1) week, min(recorded_on) from entries where user_id = 9 and weekday(recorded_on) in (5,6) group by week(recorded_on,1) order by recorded_on;

    # NOTE:  saturday,sunday is 0,6 in ruby. it is 5,6 in mysql when using mode=1 with the week argument
    if [0,6].include?(entry.recorded_on.wday)
      weekender = u.badges_earned.where(:badges=>{:name=>"Weekender"},:earned_year => u.promotion.current_date.year).size
      if entry.is_recorded && weekender < 1
        u.badges_earned.create(:badge_id => weekender_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
      end
    end
  end

  def self.do_weekend_warrior(entry)
    weekend_warrior_badge = entry.user.promotion.badges.where(:name => "Weekend Warrior").first rescue nil
    return if !weekend_warrior_badge
    u = entry.user

    if [0,6].include?(entry.recorded_on.wday)
      weekend_warrior = u.badges_earned.where(:badges=>{:name=>"Weekend Warrior"},:earned_year => u.promotion.current_date.year).size
      if weekend_warrior < 1
        sql = "
          SELECT
            COUNT(*)
          FROM (
            SELECT
              x.recorded_weekend,
              COUNT(DISTINCT y.recorded_weekend) AS number_of_weekends_logged_in_past_5
            FROM (
              SELECT
                WEEK(entries.recorded_on,1) AS recorded_weekend
              FROM entries
              WHERE
                entries.user_id = #{u.id}
                AND YEAR(entries.recorded_on) = #{entry.recorded_on.year}
                AND WEEKDAY(entries.recorded_on) IN (5,6)
                AND entries.is_recorded = 1
                GROUP BY recorded_weekend
            ) x
            JOIN (
              SELECT
                WEEK(entries.recorded_on,1) AS recorded_weekend
              FROM entries
              WHERE
                entries.user_id = #{u.id}
                AND YEAR(entries.recorded_on) = #{entry.recorded_on.year}
                AND WEEKDAY(entries.recorded_on) IN (5,6)
                AND entries.is_recorded = 1
              GROUP BY recorded_weekend
            ) y ON y.recorded_weekend BETWEEN (x.recorded_weekend - 4) AND x.recorded_weekend
            GROUP BY x.recorded_weekend
            HAVING number_of_weekends_logged_in_past_5 = 5
          ) z
        "
        earned = Badge.count_by_sql(sql) > 0 ? true : false
        if earned
          u.badges_earned.create(:badge_id => weekend_warrior_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
        end
      end
    end
  end
  
end
