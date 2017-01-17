class Badge < ApplicationModel

  attr_privacy_no_path_to_user
  attr_accessible :name, :description, :image, :category, :goal, :minimum_program_length, :promotion_id, :created_at, :updated_at
  attr_privacy :name, :description, :image, :category, :goal, :minimum_program_length, :any_user

  validates_presence_of :category, :name

  CATEGORY = {
    :days_logged       => 'days_logged',
    :weekends_logged   => 'weekends_logged',
    :correct_quizzes   => 'correct_quizzes',
    :distance_traveled => 'distance_traveled',
    :evaluation        => 'evaluation',
    :custom            => 'custom'
  }

  scope :for_promotion, lambda{ |promotion_id|
    where(:promotion_id => promotion_id)
  }

  CATEGORY.each_pair do |key, value|
    self.send(:scope, key, where(:category => value).order('goal asc'))
  end

  def self.for(promotion_or_id, conditions={})
    conditions = {
      :category => nil,
      :hidden   => false
    }.merge(conditions)

    promotion = promotion_or_id.is_a?(Integer) ? Promotion.find(promotion_or_id) : promotion_or_id
    promotion_id = promotion.is_default? ? 'null' : promotion.id

    badges = self.find_by_sql("
      SELECT
        *
      FROM `badges`
      WHERE
        `promotion_id` = #{promotion_id}
        #{"AND `category` = #{sanitize(conditions[:category])}" if !conditions[:category].nil?}
        #{"AND (`hidden` = #{sanitize(conditions[:hidden])} OR `hidden` is NULL)" if !conditions[:hidden].nil?}
      UNION
      SELECT
        *
      FROM `badges`
      WHERE
        `promotion_id` IS NULL
        AND CONCAT(`category`,`name`) NOT IN (
          SELECT
            CONCAT(`category`,`name`)
          FROM `badges`
          WHERE
            `promotion_id` = #{promotion_id}
        )
        #{"AND `category` = #{sanitize(conditions[:category])}" if !conditions[:category].nil?}
      ORDER BY `category` ASC, `goal` ASC
    ")
    return badges
  end

  def self.do_days_logged(entry)
    badges = Badge.for(entry.user.promotion_id, {:category => 'days_logged'})
    return if badges.empty?
    days_logged = 0
    Badge.uncached do
      days_logged = entry.user.entries.available.where(:is_logged => true).count
      earned_ids = entry.user.badges.days_logged.collect(&:id)
      badges.each{ |badge|
        Badge.unearn(entry.user, badge) if days_logged < badge.goal && earned_ids.include?(badge.id)
        next if days_logged < badge.goal
        Badge.earn(entry.user, badge, entry.logged_on)
      }
    end
  end

  def self.do_weekends_logged(entry)
    badges = Badge.for(entry.user.promotion_id, {:category => 'weekends_logged'})
    return if badges.empty?
    weekends_logged = 0
    Badge.uncached do
      sql = "
        SELECT
          COUNT(DISTINCT(CONCAT(YEAR(entries.logged_on), '-', WEEK(entries.logged_on,1)))) AS distinct_weekends
        FROM entries
        WHERE
          entries.user_id = #{entry.user.id}
          AND WEEKDAY(entries.logged_on) IN (5,6)
          AND entries.is_logged = 1
      "
      weekends_logged = Badge.count_by_sql(sql)
      earned_ids = entry.user.badges.weekends_logged.collect(&:id)
      badges.each{ |badge|
        Badge.unearn(entry.user, badge) if weekends_logged < badge.goal && earned_ids.include?(badge.id)
        next if weekends_logged < badge.goal
        Badge.earn(entry.user, badge, entry.logged_on)
      }
    end
  end

  # TODO: THE REST OF THE BADGES

  def self.do_academics(answer)
    return if Badge.academics.empty?
    correct_answers = 0
    Badge.uncached do
      correct_answers = answer.user.answers.correct.count
      earned_ids = answer.user.badges.academics.collect(&:id)
      Badge.academics.each{ |badge|
        Badge.unearn(answer.user, badge) if correct_answers < badge.goal && earned_ids.include?(badge.id)
        next if correct_answers < badge.goal
        Badge.earn(answer.user, badge, answer.created_at.to_date)
      }
    end
  end

  def self.do_perfect_landing(entry)
    return if Badge.perfect_landings.empty?
    total_points = 0
    Badge.uncached do
      total_points = entry.user.total_points
      earned_ids = entry.user.badges.perfect_landings.collect(&:id)
      badge = Badge.perfect_landings.first
      if total_points >= entry.user.promotion.points_goal
        Badge.earn(entry.user, badge, entry.logged_on)
      else
        if earned_ids.include?(badge.id)
          Badge.unearn(entry.user, badge)
        end
      end
    end
  end

  def self.do_baggage_claim(evaluation)
    return if Badge.baggage_claims.empty?
    Badge.uncached do
      earned_ids = evaluation.user.badges.baggage_claims.collect(&:id)
      eval_ids = evaluation.user.evaluations.collect(&:evaluation_definition_id)
      last_eval_def_id = evaluation.user.promotion.evaluation_definitions.last.id
      badge = Badge.baggage_claims.first
      if eval_ids.include?(last_eval_def_id)
        Badge.earn(evaluation.user, badge, evaluation.created_at.to_date)
      else
        if earned_ids.include?(badge.id)
          # hasn't met criteria but earned badge (this should be rather impossible with evals, but whatevs)
          Badge.unearn(evaluation.user, badge) 
        end
      end
    end
  end

  def self.do_points_rewards(user)
    return if Badge.points_rewards.empty? || Badge.points_rewards.where(:promotion_id => user.promotion_id).empty?
    badges = Badge.points_rewards.where(:promotion_id => user.promotion_id)
    Badge.uncached do
      earned_ids = user.badges.points_rewards.collect(&:id)
      badges.each{ |badge|
        Badge.unearn(user, badge) if user.total_points < badge.goal && earned_ids.include?(badge.id)
        next if user.total_points < badge.goal
        Badge.earn(user, badge, Date.today.to_s(:db))
      }
    end
  end

  def self.do_patches_rewards(user)
    return if Badge.patches_rewards.empty? || Badge.patches_rewards.where(:promotion_id => user.promotion_id).empty?
    badges = Badge.patches_rewards.where(:promotion_id => user.promotion_id)
    Badge.uncached do
      earned_ids = user.badges.patches_rewards.collect(&:id)
      badges_earned_count_not_including_patches_rewards = user.badges.where("badges.badge_type <> 'patches_reward' && badges.badge_type <> 'points_reward'").count
      badges.each{ |badge|
        Badge.unearn(user, badge) if badges_earned_count_not_including_patches_rewards < badge.goal && earned_ids.include?(badge.id)
        next if badges_earned_count_not_including_patches_rewards < badge.goal
        Badge.earn(user, badge, Date.today.to_s(:db))
      }
    end
  end

  def self.earn(user, badge, date = Date.today)
    date = Date.parse(date) if date.is_a?(String)
    year = date.year
    ub = user.badges_earned.find_by_badge_id(badge.id) rescue nil
    user.badges_earned.create(:badge_id => badge.id, :earned_year => year, :earned_date => date) if ub.nil?
  end

  def self.unearn(user, badge)
    ub = user.badges_earned.find_by_badge_id(badge.id) rescue nil
    ub.destroy if !ub.nil?
  end

  def self.promotionize(collection, promotion)
    collection = [collection] if !collection.is_a?(Array) && collection.class != ActiveRecord::Relation
    collection.each{ |badge|
      badge = badge.badge if badge.class == UserBadge
      next if badge.badge_type != 'perfect_landing'
      badge.name = badge.name.gsub(/PROMOTION_POINTS_GOAL/, promotion.points_goal.to_s)
      badge.description = badge.description.gsub(/PROMOTION_POINTS_GOAL/, promotion.points_goal.to_s)
    }
    return collection
  end

end
