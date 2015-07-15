class Badge < ActiveRecord::Base

  attr_privacy_no_path_to_user
  attr_accessible *column_names
  attr_privacy :promotion_id, :name, :description, :completion_message, :image, :unearned_image, :badge_type, :point_goal, :sequence, :any_user

  validates_presence_of :badge_type, :promotion_id, :name

  belongs_to :promotion

  mount_uploader :image, BadgeImageUploader

  TYPE = {
    :milestones   => 'milestone',
    :achievements => 'achievement'
  }

  SOCIAL_MEDIA_TYPES = ['facebook','twitter']

  TYPE.each_pair do |key, value|
    self.send(:scope, key, where(:badge_type => value))
  end

  def self.possible(for_promotion,year)
    # ignoring for_promotion and year for now
    # eventually we'll want to do something with those...
    Milestones.keys.concat([Weekender,WeekendWarrior])
  end

  # handles inserts, updates & deletes - presently only used with do_milestones
  # TODO: either start using this everywhere cuz it's faster, or get rid of it cuz it's confusing
  def self.process_for_user(user_id, earned_date, options = {})
    u = User.find(user_id) rescue nil
    return if !u

    options[:create]  ||= [] # [badge_id, earned_date]
    options[:update]  ||= [] # [badge_id, earned_date]
    options[:destroy] ||= [] # badge_id

    now = u.promotion.current_time.to_s(:db)

    connection.execute("DELETE FROM user_badges WHERE user_id = #{user_id} AND earned_year = #{earned_date.year} AND badge_id IN (#{options[:destroy].join(",")})") unless options[:destroy].empty?

    badges_added = []
    options[:create].each_with_index{|create,index|
      badges_added << options[:create][index][0]
      options[:create][index] = [user_id, options[:create][index][0], options[:create][index][1].year, "'#{options[:create][index][1]}'", "'#{now}'", "'#{now}'"].join(',')
      options[:create][index] = "(#{options[:create][index]})"
    }

    unless options[:create].empty?
      connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES #{options[:create].join(",\n")}")
      # we aren't using ActiveRecord so send notifications for these badges manually
      Badge.uncached do
        UserBadge.where(:user_id => user_id, :earned_year => earned_date.year, :badge_id => badges_added).each{|ub|
          ub.send_notification()
        }
      end
    end

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
            @runtot := 0, SUM(e.exercise_points + e.gift_points + e.behavior_points) total_points, e.recorded_on as_of
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

    milestone_id = false

    if !deletes.empty? && deletes.include?(entry.user.milestone_id) && inserts.empty?
      milestone_id = "null" # DB value
    elsif !inserts.empty?
      milestone_id = inserts.last.first
    end

    if milestone_id != false
      update_sql = "UPDATE users SET milestone_id = #{milestone_id} WHERE id = #{entry.user_id}"
      Rails.logger.warn "Updating milestone for User #{entry.user_id}: #{update_sql}"
      connection.execute(update_sql)
    end

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

    connection.execute("DELETE FROM user_badges WHERE user_id = #{entry.user_id} AND id IN (#{process[:destroy].join(",")})") unless process[:destroy].empty?

    process[:create].each_with_index{|create,index|
      process[:create][index] = [entry.user.id, process[:create][index][:badge_id], process[:create][index][:earned_date].year, "'#{process[:create][index][:earned_date]}'", "'#{now}'", "'#{now}'"].join(',')
      process[:create][index] = "(#{process[:create][index]})"
    }

    unless process[:create].empty?
      connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES #{process[:create].join(",\n")}")
      # we aren't using ActiveRecord so send notifications for these badges manually
      Badge.uncached do
        ub = UserBadge.where(:user_id => entry.user.id, :earned_year => entry.user.promotion.current_date.year, :badge_id => goal_getter_badge.id).first rescue nil
        ub.send_notification() if ub
      end
    end

    return true

  end

  def self.do_enthusiast(post)
    return unless post.depth == 0 && post.wallable.id == post.user.promotion.id
    enthusiast_badge = post.user.promotion.badges.where(:name => "Enthusiast").first rescue nil
    return if !enthusiast_badge
    Badge.uncached do
      num = post.user.posts.where(:wallable_type => 'Promotion', :wallable_id => post.user.promotion.id, :depth => 0).where("created_at BETWEEN '#{post.created_at.beginning_of_week.to_time.to_s(:db)}' AND '#{post.created_at.end_of_week.to_time.to_s(:db)}'").size
      if num > 2 && post.user.badges_earned.where(:earned_year => post.created_at.year, :badge_id => enthusiast_badge.id).size < 1
        # TODO: possibly destroy?
        now = post.user.promotion.current_time.to_s(:db)
        connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES (#{post.user.id}, #{enthusiast_badge.id}, #{post.created_at.year}, '#{post.created_at.to_date.to_s(:db)}', '#{now}', '#{now}')")
        # we aren't using ActiveRecord so send notifications for these badges manually
        Badge.uncached do
          ub = UserBadge.where(:user_id => post.user.id, :earned_year => post.user.promotion.current_date.year, :badge_id => enthusiast_badge.id).first rescue nil
          ub.send_notification() if ub
        end
      end
    end
    return true
  end

  def self.do_sidekick(friendship)
    sidekick_badge = friendship.friender.promotion.badges.where(:name => "Sidekick").first rescue nil
    return if !sidekick_badge
    Badge.uncached do
      now = friendship.friender.promotion.current_time.to_s(:db)
      # friendee...
      u = friendship.friendee
      if friendship.friendee && friendship.friendee.friends.size > 9
        if friendship.friendee.badges_earned.where(:earned_year => friendship.updated_at.year, :badge_id => sidekick_badge.id).size < 1
          connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES (#{u.id}, #{sidekick_badge.id}, #{friendship.updated_at.year}, '#{friendship.updated_at.to_date.to_s(:db)}', '#{now}', '#{now}')")
          # we aren't using ActiveRecord so send notifications for these badges manually
          Badge.uncached do
            ub = UserBadge.where(:user_id => u.id, :earned_year => u.promotion.current_date.year, :badge_id => sidekick_badge.id).first rescue nil
            ub.send_notification() if ub
          end
        end
      else
        # TODO: i don't think we really want to do this.. i think we want to keep all badges
        # remove sidekick
        # connection.execute("DELETE FROM user_badges WHERE user_id = #{u.id} AND earned_year = #{friendship.updated_at.year} AND badge_id = #{sidekick_badge.id}")
      end
      # friender...
      u = friendship.friender
      if friendship.friender && friendship.friender.friends.size > 9
        if friendship.friender.badges_earned.where(:earned_year => friendship.updated_at.year, :badge_id => sidekick_badge.id).size < 1
          connection.execute("INSERT INTO user_badges (user_id, badge_id, earned_year, earned_date, created_at, updated_at) VALUES (#{u.id}, #{sidekick_badge.id}, #{friendship.updated_at.year}, '#{friendship.updated_at.to_date.to_s(:db)}', '#{now}', '#{now}')")
          # we aren't using ActiveRecord so send notifications for these badges manually
          Badge.uncached do
            ub = UserBadge.where(:user_id => u.id, :earned_year => u.promotion.current_date.year, :badge_id => sidekick_badge.id).first rescue nil
            ub.send_notification() if ub
          end
        end
      else
        # TODO: i don't think we really want to do this.. i think we want to keep all badges
        # remove sidekick badge
        # connection.execute("DELETE FROM user_badges WHERE user_id = #{u.id} AND earned_year = #{friendship.updated_at.year} AND badge_id = #{sidekick_badge.id}")
      end
    end
  end

  def self.do_applause(like)
    # TODO: possibly destroy?
    applause_badge = like.user.promotion.badges.where(:name => "Applause").first rescue nil
    return if !applause_badge
    Badge.uncached do
      u = like.likeable.user
      likes = like.likeable.likes.where("YEAR(created_at) = #{u.promotion.current_date.year}").size
      applause = u.badges_earned.where(:badges=>{:name=>"Applause"},:earned_year => u.promotion.current_date.year).size
      if applause < 1 && likes > 9
        u.badges_earned.create(:badge_id => applause_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
      end
    end
  end

  def self.do_high_five(like)
    # TODO: possibly destroy?
    high_five_badge = like.user.promotion.badges.where(:name => "High Five").first rescue nil
    return if !high_five_badge
    Badge.uncached do
      u = like.user
      likes = u.likes.where(:likeable_type => "Post").where("YEAR(created_at) = #{u.promotion.current_date.year}").size
      high_five = u.badges_earned.where(:badges=>{:name=>"High Five"},:earned_year => u.promotion.current_date.year).size
      if high_five < 1 && likes > 9
        u.badges_earned.create(:badge_id => high_five_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
      end
    end
  end

  def self.do_chef(share)
    # TODO: possibly destroy?
    chef_badge = share.user.promotion.badges.where(:name => "Chef").first rescue nil
    return if !chef_badge
    return if share.shareable_type != 'Recipe' || !Badge::SOCIAL_MEDIA_TYPES.include?(share.via)
    Badge.uncached do
      u = share.user
      chef =  u.badges_earned.where(:badges=>{:name=>"Chef"},:earned_year => u.promotion.current_date.year).size
      if chef < 1 && u.shares.typed("Recipe").where("YEAR(created_at) = #{u.promotion.current_date.year}").size > 0
        u.badges_earned.create(:badge_id => chef_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
      end
    end
  end

  def self.do_head_chef(share)
    # TODO: possibly destroy?
    head_chef_badge = share.user.promotion.badges.where(:name => "Head Chef").first rescue nil
    return if !head_chef_badge
    return if share.shareable_type != 'Recipe' || !Badge::SOCIAL_MEDIA_TYPES.include?(share.via)
    Badge.uncached do
      u = share.user
      head_chef =  u.badges_earned.where(:badges=>{:name=>"Head Chef"},:earned_year => u.promotion.current_date.year).size
      if head_chef < 1 && u.shares.typed("Recipe").where("YEAR(created_at) = #{u.promotion.current_date.year}").size > 4
        u.badges_earned.create(:badge_id => head_chef_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
      end
    end
  end

  def self.do_tipster(share)
    # TODO: possibly destroy?
    tipster_badge = share.user.promotion.badges.where(:name => "Tipster").first rescue nil
    return if !tipster_badge
    return if share.shareable_type != 'Tip' || !Badge::SOCIAL_MEDIA_TYPES.include?(share.via)
    Badge.uncached do
      u = share.user
      tipster =  u.badges_earned.where(:badges=>{:name=>"Tipster"},:earned_year => u.promotion.current_date.year).size
      if tipster < 1 && u.shares.typed("Tip").where("YEAR(created_at) = #{u.promotion.current_date.year}").size > 0
        u.badges_earned.create(:badge_id => tipster_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
      end
    end
  end

  def self.do_uber_tipster(share)
    # TODO: possibly destroy?
    uber_tipster_badge = share.user.promotion.badges.where(:name => "Uber Tipster").first rescue nil
    return if !uber_tipster_badge
    return if share.shareable_type != 'Tip' || !Badge::SOCIAL_MEDIA_TYPES.include?(share.via)
    Badge.uncached do
      u = share.user
      uber_tipster =  u.badges_earned.where(:badges=>{:name=>"Uber Tipster"},:earned_year => u.promotion.current_date.year).size
      if uber_tipster < 1 && u.shares.typed("Tip").where("YEAR(created_at) = #{u.promotion.current_date.year}").size > 4
        u.badges_earned.create(:badge_id => uber_tipster_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
      end
    end
  end

  def self.do_weekender(entry)
    weekender_badge = entry.user.promotion.badges.where(:name => "Weekender").first rescue nil
    return if !weekender_badge
    Badge.uncached do
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
  end

  def self.do_weekend_warrior(entry)
    weekend_warrior_badge = entry.user.promotion.badges.where(:name => "Weekend Warrior").first rescue nil
    return if !weekend_warrior_badge

    Badge.uncached do

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

  def self.do_food_critic(rating)
    # TODO: possibly destroy?
    food_critic_badge = rating.user.promotion.badges.where(:name => "Food Critic").first rescue nil
    return if !food_critic_badge
    Badge.uncached do
      u = rating.user
      ratings = u.ratings.typed("Recipe").where("YEAR(created_at) = #{u.promotion.current_date.year}").size
      food_critic = u.badges_earned.where(:badges=>{:name=>"Food Critic"},:earned_year => u.promotion.current_date.year).size
      if food_critic < 1 && ratings > 9
        u.badges_earned.create(:badge_id => food_critic_badge.id, :earned_date => u.promotion.current_date, :earned_year => u.promotion.current_date.year)
      end
    end
  end
  
end
