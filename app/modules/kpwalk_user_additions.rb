module KpwalkUserAdditions
  KPWALK_DATABASE_NAME = Rails.env.production? ? "kpwalks" : "kpwalks_development"

  def self.included(base)
    base.extend ClassMethods

    base.send :attr_accessor, :kpwalk_token
    base.send :attr_accessible, :kpwalk_token

    base.send :before_create, :tie_to_kpwalk
  end
    
  def get_kpwalk_token
    if self.kpwalk_user_id
      sql = "select gokp_token from #{KPWALK_DATABASE_NAME}.users where id = #{sanitize(self.id)}"
      rows = User.connection.select_all(sql)
      unless rows.empty?
        rows.first['gokp_token']
      else
        nil
      end
    else
      nil
    end
  end

  def tie_to_kpwalk
    if self.kpwalk_token
      kpwalk_data = self.class.get_kpwalk_data_from_token(self.kpwalk_token)
      if kpwalk_data
        Rails.logger.warn "tying to kpwalk User##{kpwalk_data['user_id']} with token: #{self.kpwalk_token}"
        self.kpwalk_user_id = kpwalk_data['user_id']
        self.kpwalk_total_stars = kpwalk_data['total_stars_earned']
        m = kpwalk_data['total_exercise_minutes']
        self.kpwalk_total_minutes = m
        if m >= 75000
          self.kpwalk_level = 'diamond'
        elsif m >= 40000
          self.kpwalk_level = 'platinum'
        elsif m >= 20000
          self.kpwalk_level = 'gold'
        elsif m >= 15000
          self.kpwalk_level = 'silver'
        elsif m >= 7000
          self.kpwalk_level = 'bronze'
        else
          self.kpwalk_level = nil
        end
      else
        Rails.logger.warn "no kpwalk user with token: #{self.kpwalk_token}"
      end
    else
      Rails.logger.warn "no kpwalk token"
    end
  end

  module ClassMethods
    def get_kpwalk_authenticate_sql(email)
      "select contacts.email, users.password, users.gokp_token, users.id user_id
       from #{KPWALK_DATABASE_NAME}.users
       inner join #{KPWALK_DATABASE_NAME}.contacts on #{KPWALK_DATABASE_NAME}.contacts.contactable_type = 'User' and #{KPWALK_DATABASE_NAME}.contacts.contactable_id = #{KPWALK_DATABASE_NAME}.users.id
       inner join #{KPWALK_DATABASE_NAME}.promotions on #{KPWALK_DATABASE_NAME}.promotions.id = #{KPWALK_DATABASE_NAME}.users.promotion_id
       where #{KPWALK_DATABASE_NAME}.promotions.is_active = 1 and #{KPWALK_DATABASE_NAME}.contacts.email = #{sanitize(email)}
       order by #{KPWALK_DATABASE_NAME}.users.promotion_id"
    end

    def get_kpwalk_user_id_from_token(token)
      if token
        sql = "select id from #{KPWALK_DATABASE_NAME}.users where gokp_token = #{sanitize(token)}"
        rows = User.connection.select_all(sql)
        unless rows.empty?
          rows.first['id']
        else
          nil
        end
      else
        nil
      end
    end

    def get_kpwalk_data_from_token(token)
      sql = get_kpwalk_show_sql_from_token(token)
      rows = connection.select_all(sql)
      rows.first
    end

    def get_kpwalk_data_from_user_id(user_id)
      sql = get_kpwalk_show_sql_from_user_id(user_id)
      rows = connection.select_all(sql)
      rows.first
    end

    def get_kpwalk_show_sql_from_token(token)
      get_kpwalk_show_sql "#{KPWALK_DATABASE_NAME}.users.gokp_token = #{sanitize(token)}"
    end

    def get_kpwalk_show_sql_from_user_id(user_id)
      get_kpwalk_show_sql "#{KPWALK_DATABASE_NAME}.users.id = #{sanitize(user_id)}"
    end

    def get_kpwalk_show_sql(conditions)
      sql = "select users.id user_id, contacts.first_name, contacts.last_name, contacts.email, 
             profiles.nuid, profiles.entity, profiles.employee_group,
             sum(entries.exercise_minutes) total_exercise_minutes, sum(entries.is_level_earned) total_stars_earned,
             promotion_locations.name location, top_level_locations.name top_level_location
             from #{KPWALK_DATABASE_NAME}.users
             inner join #{KPWALK_DATABASE_NAME}.contacts on #{KPWALK_DATABASE_NAME}.contacts.contactable_type = 'User' and #{KPWALK_DATABASE_NAME}.contacts.contactable_id = #{KPWALK_DATABASE_NAME}.users.id
             inner join #{KPWALK_DATABASE_NAME}.trips on #{KPWALK_DATABASE_NAME}.trips.user_id = #{KPWALK_DATABASE_NAME}.users.id
             inner join #{KPWALK_DATABASE_NAME}.entries on #{KPWALK_DATABASE_NAME}.entries.trip_id = #{KPWALK_DATABASE_NAME}.trips.id
             inner join #{KPWALK_DATABASE_NAME}.profiles on #{KPWALK_DATABASE_NAME}.profiles.trip_id = #{KPWALK_DATABASE_NAME}.trips.id
             left join #{KPWALK_DATABASE_NAME}.promotion_locations on #{KPWALK_DATABASE_NAME}.promotion_locations.id = #{KPWALK_DATABASE_NAME}.users.location_id
             left join #{KPWALK_DATABASE_NAME}.promotion_locations top_level_locations on top_level_locations.id = #{KPWALK_DATABASE_NAME}.users.top_level_location_id
             where #{conditions} 
             group by #{KPWALK_DATABASE_NAME}.users.id"
    end
  end
end
